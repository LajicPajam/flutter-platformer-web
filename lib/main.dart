import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game_logic.dart';
import 'level_data.dart';
import 'physics.dart';

void main() {
  runApp(const PlatformerApp());
}

class PlatformerApp extends StatelessWidget {
  const PlatformerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Bryce's Pizza Quest",
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrangeAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  static const Size _playerSize = Size(42, 42);
  static const double _moveSpeed = 280;
  static const double _jumpVelocity = -640;
  static const double _gravity = 1900;
  static const double _terminalVelocity = 980;

  final FocusNode _focusNode = FocusNode();
  late final Ticker _ticker;
  final DoubleJumpController _jumpController = DoubleJumpController(maxJumps: 2);
  final LivesSystem _livesSystem = LivesSystem(maxLives: 3);
  final List<LevelDefinition> _levels = buildLevelDefinitions();

  LevelInstance? _levelInstance;
  int _currentLevelIndex = 0;
  Offset _playerPosition = const Offset(60, 680);
  double _velocityX = 0;
  double _velocityY = 0;
  bool _grounded = false;
  bool _levelCleared = false;
  bool _victory = false;
  bool _gameOver = false;
  double _cameraX = 0;
  Duration? _lastTick;
  Size? _viewportSize;
  String? _statusBanner;
  DateTime? _bannerExpiry;

  Rect get _playerRect => Rect.fromLTWH(
        _playerPosition.dx,
        _playerPosition.dy,
        _playerSize.width,
        _playerSize.height,
      );

  LevelInstance get _currentLevel => _levelInstance ??= _levels.first.createInstance();

  Size get _worldSize => _currentLevel.definition.worldSize;

  bool get _isPaused => _levelCleared || _victory || _gameOver;

  @override
  void initState() {
    super.initState();
    _loadLevel(0);
    _focusNode.requestFocus();
    _ticker = createTicker(_handleTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadLevel(int index) {
    _currentLevelIndex = index;
    _levelInstance = _levels[index].createInstance();
    _respawn(resetLives: false);
  }

  void _respawn({required bool resetLives}) {
    _levelInstance?.resetDynamicState();
    final level = _levels[_currentLevelIndex];
    _playerPosition = level.spawn;
    _velocityX = 0;
    _velocityY = 0;
    _grounded = false;
    _jumpController.reset();
    _cameraX = 0;
    if (resetLives) {
      _livesSystem.reset();
    }
  }

  void _handleTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) {
      return;
    }

    if (_isPaused || _viewportSize == null) {
      _maybeClearBanner();
      return;
    }

    double delta = (elapsed - last).inMicroseconds / 1e6;
    delta = delta.clamp(0.0, 1 / 30);

    if (_leftPressed && !_rightPressed) {
      _velocityX = -_moveSpeed;
    } else if (_rightPressed && !_leftPressed) {
      _velocityX = _moveSpeed;
    } else {
      _velocityX = 0;
    }

    _velocityY = applyGravity(
      currentVelocity: _velocityY,
      gravity: _gravity,
      deltaSeconds: delta,
      terminalVelocity: _terminalVelocity,
    );

    for (final enemy in _currentLevel.enemies) {
      enemy.update(delta);
    }

    _moveHorizontally(delta);
    _moveVertically(delta);
    _collectIngredients();
    _checkHazards();
    _checkGoalReached();
    _updateCamera();
    _maybeClearBanner();

    if (mounted) {
      setState(() {});
    }
  }

  bool _leftPressed = false;
  bool _rightPressed = false;

  void _moveHorizontally(double delta) {
    if (_velocityX == 0) {
      return;
    }
    double nextX = _playerPosition.dx + _velocityX * delta;
    Rect future = Rect.fromLTWH(nextX, _playerPosition.dy, _playerSize.width, _playerSize.height);

    for (final platform in _currentLevel.definition.platforms) {
      if (future.overlaps(platform)) {
        if (_velocityX > 0) {
          nextX = platform.left - _playerSize.width - 0.1;
        } else {
          nextX = platform.right + 0.1;
        }
        future = Rect.fromLTWH(nextX, _playerPosition.dy, _playerSize.width, _playerSize.height);
        _velocityX = 0;
      }
    }

    nextX = nextX.clamp(0.0, _worldSize.width - _playerSize.width);
    _playerPosition = Offset(nextX, _playerPosition.dy);
  }

  void _moveVertically(double delta) {
    double nextY = _playerPosition.dy + _velocityY * delta;
    Rect future = Rect.fromLTWH(_playerPosition.dx, nextY, _playerSize.width, _playerSize.height);
    bool grounded = false;

    for (final platform in _currentLevel.definition.platforms) {
      if (future.overlaps(platform)) {
        if (_velocityY > 0) {
          nextY = platform.top - _playerSize.height;
          grounded = true;
        } else if (_velocityY < 0) {
          nextY = platform.bottom + 0.1;
        }
        future = Rect.fromLTWH(_playerPosition.dx, nextY, _playerSize.width, _playerSize.height);
        _velocityY = 0;
      }
    }

    _playerPosition = Offset(
      _playerPosition.dx,
      nextY.clamp(0.0, _worldSize.height - _playerSize.height),
    );
    _grounded = grounded;
    if (_grounded) {
      _jumpController.reset();
    }

    if (_playerPosition.dy > _worldSize.height + 200) {
      _handleDeath(reason: 'Bryce slipped into the void');
    }
  }

  void _collectIngredients() {
    final playerRect = _playerRect;
    for (final ingredient in _currentLevel.ingredients) {
      if (!ingredient.collected && playerRect.overlaps(ingredient.rect)) {
        ingredient.collected = true;
        _showBanner('Bryce grabbed ${ingredientLabel(ingredient.type)}!');
      }
    }
  }

  void _checkHazards() {
    final playerRect = _playerRect;
    for (final hazard in _currentLevel.definition.hazards) {
      if (playerRect.overlaps(hazard)) {
        _handleDeath(reason: 'Spikes hurt!');
        return;
      }
    }
    for (final enemy in _currentLevel.enemies) {
      if (playerRect.overlaps(enemy.rect)) {
        _handleDeath(reason: 'A rival chef tackled Bryce');
        return;
      }
    }
  }

  void _checkGoalReached() {
    if (_victory || _gameOver || _levelCleared) {
      return;
    }
    final exitRect = _levels[_currentLevelIndex].exit;
    if (_playerRect.overlaps(exitRect) && _currentLevel.tracker.isComplete) {
      if (_currentLevelIndex == _levels.length - 1) {
        setState(() {
          _victory = true;
        });
      } else {
        setState(() {
          _levelCleared = true;
        });
      }
    }
  }

  void _updateCamera() {
    final viewport = _viewportSize;
    if (viewport == null) {
      return;
    }
    _cameraX = clampCameraOffset(
      playerCenter: _playerPosition.dx + _playerSize.width / 2,
      viewportWidth: viewport.width,
      levelWidth: _worldSize.width,
    );
  }

  void _handleDeath({required String reason}) {
    if (_gameOver || _victory) {
      return;
    }
    final isGameOver = _livesSystem.loseLife();
    if (isGameOver) {
      setState(() {
        _gameOver = true;
      });
      return;
    }
    _showBanner(reason);
    _respawn(resetLives: false);
  }

  void _showBanner(String message) {
    _statusBanner = message;
    _bannerExpiry = DateTime.now().add(const Duration(seconds: 3));
  }

  void _maybeClearBanner() {
    final expiry = _bannerExpiry;
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      _statusBanner = null;
      _bannerExpiry = null;
    }
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.repeat) {
      return;
    }

    final key = event.logicalKey;
    final isDown = event is RawKeyDownEvent;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _leftPressed = isDown;
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _rightPressed = isDown;
    }

    if (isDown && (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.space)) {
      _attemptJump();
    }

    if (isDown && key == LogicalKeyboardKey.keyR && (_gameOver || _victory)) {
      _restartCampaign();
    }
  }

  void _attemptJump() {
    if (_jumpController.canJump && !_levelCleared && !_victory && !_gameOver) {
      _velocityY = _jumpVelocity;
      _jumpController.registerJump();
      _grounded = false;
    }
  }

  void _restartCampaign() {
    setState(() {
      _victory = false;
      _gameOver = false;
      _levelCleared = false;
      _statusBanner = null;
      _bannerExpiry = null;
      _loadLevel(0);
      _respawn(resetLives: true);
    });
  }

  void _advanceLevel() {
    setState(() {
      _levelCleared = false;
      _loadLevel(_currentLevelIndex + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: _handleKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: GamePainter(
                      level: _currentLevel,
                      player: _playerRect,
                      cameraX: _cameraX,
                      exitUnlocked: _currentLevel.tracker.isComplete,
                    ),
                  ),
                  _buildHud(),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          "Bryce's Pizza Quest: use Arrow/WASD to move, Space/Up for jumps."
                          " Collect every ingredient to light up the exit portal."
                          " Double-jump by tapping jump again while airborne.",
                        ),
                      ),
                    ),
                  ),
                  if (_statusBanner != null)
                    Positioned(
                      top: 110,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_statusBanner!),
                          ),
                        ),
                      ),
                    ),
                  if (_levelCleared)
                    _buildBlockingOverlay(
                      title: 'Level clear!',
                      description: 'Bryce gathered every ingredient. Ready for the next delivery?',
                      primaryLabel: 'Next level',
                      onPrimary: _advanceLevel,
                    ),
                  if (_victory)
                    _buildBlockingOverlay(
                      title: 'Pizza Perfect! 🍕',
                      description: 'Bryce assembled the ultimate pie. Time to feed the city.',
                      primaryLabel: 'Restart Quest',
                      onPrimary: _restartCampaign,
                    ),
                  if (_gameOver)
                    _buildBlockingOverlay(
                      title: 'Game Over',
                      description: 'Bryce ran out of aprons. Try the quest again!',
                      primaryLabel: 'Restart Quest',
                      onPrimary: _restartCampaign,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    final level = _levels[_currentLevelIndex];
    final tracker = _currentLevel.tracker;
    final ingredientChips = tracker.ingredients
        .map((ingredient) => _IngredientChip(
              label: ingredientLabel(ingredient.type),
              collected: ingredient.collected,
              type: ingredient.type,
            ))
        .toList();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Bryce's Pizza Quest — Level ${_currentLevelIndex + 1}/${_levels.length}: ${level.name}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_pizza, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text('Lives: ${_livesSystem.remaining}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.double_arrow, size: 18),
                  const SizedBox(width: 4),
                  const Text('Double Jump Ready: '),
                  Text(_jumpController.canJump || _grounded ? 'Yes' : 'Used'),
                ],
              ),
              const SizedBox(height: 8),
              if (ingredientChips.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ingredientChips,
                )
              else
                const Text('No ingredients required — head for the exit!'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockingOverlay({
    required String title,
    required String description,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.75)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 320,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onPrimary,
                icon: const Icon(Icons.replay),
                label: Text(primaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({
    required this.label,
    required this.collected,
    required this.type,
  });

  final String label;
  final bool collected;
  final IngredientType type;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (type) {
      case IngredientType.dough:
        color = const Color(0xFFfb923c);
        break;
      case IngredientType.sauce:
        color = const Color(0xFFef4444);
        break;
      case IngredientType.cheese:
        color = const Color(0xFFfacc15);
        break;
      case IngredientType.toppings:
        color = const Color(0xFF4ade80);
        break;
    }

    return Chip(
      avatar: Icon(
        collected ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
        color: collected ? Colors.limeAccent : Colors.white70,
      ),
      backgroundColor: collected ? color.withOpacity(0.3) : Colors.white12,
      label: Text('$label ${collected ? '✓' : '…'}'),
    );
  }
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.level,
    required this.player,
    required this.cameraX,
    required this.exitUnlocked,
  });

  final LevelInstance level;
  final Rect player;
  final double cameraX;
  final bool exitUnlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), background);

    canvas.save();
    canvas.translate(-cameraX, 0);

    final platformPaint = Paint()..color = const Color(0xFF334155);
    final edgePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final platform in level.definition.platforms) {
      final rrect = RRect.fromRectAndRadius(platform, const Radius.circular(6));
      canvas.drawRRect(rrect, platformPaint);
      canvas.drawRRect(rrect, edgePaint);
    }

    final hazardPaint = Paint()
      ..color = const Color(0xFFb91c1c)
      ..style = PaintingStyle.fill;
    for (final hazard in level.definition.hazards) {
      canvas.drawRect(hazard, hazardPaint);
    }

    for (final enemy in level.enemies) {
      final rect = enemy.rect;
      final enemyPaint = Paint()..color = const Color(0xFFf472b6);
      canvas.drawRect(rect, enemyPaint);
      canvas.drawRect(
        rect.deflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withOpacity(0.6),
      );
    }

    for (final ingredient in level.ingredients) {
      final Color baseColor = switch (ingredient.type) {
        IngredientType.dough => const Color(0xFFfb923c),
        IngredientType.sauce => const Color(0xFFef4444),
        IngredientType.cheese => const Color(0xFFfacc15),
        IngredientType.toppings => const Color(0xFF4ade80),
      };
      final paint = Paint()
        ..color = ingredient.collected ? baseColor.withOpacity(0.2) : baseColor;
      final rect = ingredient.rect;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);
      if (ingredient.collected) {
        canvas.drawLine(
          rect.topLeft,
          rect.bottomRight,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2,
        );
      }
    }

    final exitPaint = Paint()
      ..color = exitUnlocked ? const Color(0xFFbef264) : const Color(0xFFfcd34d)
      ..style = PaintingStyle.fill;
    final exitOutline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final exitRect = level.definition.exit;
    final exitRRect = RRect.fromRectAndRadius(exitRect, const Radius.circular(10));
    canvas.drawRRect(exitRRect, exitPaint);
    canvas.drawRRect(exitRRect, exitOutline);

    final playerPaint = Paint()..color = const Color(0xFF38bdf8);
    final playerRRect = RRect.fromRectAndRadius(player, const Radius.circular(8));
    canvas.drawRRect(playerRRect, playerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}
