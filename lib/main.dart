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
  bool _showMenu = true;
  double _cameraX = 0;
  Duration? _lastTick;
  Size? _viewportSize;
  String? _statusBanner;
  DateTime? _bannerExpiry;
  Offset _currentRespawnPoint = Offset.zero;
  int _activeCheckpointIndex = -1;

  Rect get _playerRect => Rect.fromLTWH(
        _playerPosition.dx,
        _playerPosition.dy,
        _playerSize.width,
        _playerSize.height,
      );

  LevelInstance get _currentLevel => _levelInstance ??= _levels.first.createInstance();

  Size get _worldSize => _currentLevel.definition.worldSize;

  bool get _isPaused => _showMenu || _levelCleared || _victory || _gameOver;

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
    _statusBanner = null;
    _bannerExpiry = null;
    _activeCheckpointIndex = -1;
    _currentRespawnPoint = _levels[index].spawn;
    _respawn(resetLives: false, fullReset: true);
  }

  void _respawn({required bool resetLives, required bool fullReset}) {
    _levelInstance?.resetDynamicState(full: fullReset);
    final level = _levels[_currentLevelIndex];
    if (fullReset) {
      _currentRespawnPoint = level.spawn;
      _activeCheckpointIndex = -1;
    }
    _playerPosition = fullReset ? level.spawn : _currentRespawnPoint;
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
    _checkCheckpoints();
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
        _showBanner('Bryce grabbed ${ingredient.displayName}!');
      }
    }
  }

  void _checkCheckpoints() {
    final playerRect = _playerRect;
    final checkpoints = _currentLevel.checkpoints;
    for (var i = 0; i < checkpoints.length; i++) {
      final checkpoint = checkpoints[i];
      if (!checkpoint.activated && playerRect.overlaps(checkpoint.definition.area)) {
        checkpoint.activated = true;
        _activeCheckpointIndex = i;
        _currentRespawnPoint = checkpoint.definition.respawn;
        _showBanner('Checkpoint: ${checkpoint.definition.label}');
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
    _respawn(resetLives: false, fullReset: false);
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

    if (_showMenu && isDown &&
        (key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.keyP)) {
      _beginQuest();
      return;
    }

    if (_showMenu) {
      return;
    }

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

  void _beginQuest() {
    setState(() {
      _showMenu = false;
      _victory = false;
      _gameOver = false;
      _levelCleared = false;
      _statusBanner = null;
      _bannerExpiry = null;
      _loadLevel(0);
      _respawn(resetLives: true, fullReset: true);
    });
  }

  void _restartCampaign() {
    setState(() {
      _showMenu = false;
      _victory = false;
      _gameOver = false;
      _levelCleared = false;
      _statusBanner = null;
      _bannerExpiry = null;
      _loadLevel(0);
      _respawn(resetLives: true, fullReset: true);
    });
  }

  void _returnToTitle() {
    setState(() {
      _showMenu = true;
      _victory = false;
      _gameOver = false;
      _levelCleared = false;
      _statusBanner = null;
      _bannerExpiry = null;
      _loadLevel(0);
      _respawn(resetLives: true, fullReset: true);
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
                      themeLabel: _levels[_currentLevelIndex].theme,
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
                  if (_showMenu) _buildHomeScreen(context),
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
                      secondaryLabel: 'Back to Title',
                      onSecondary: _returnToTitle,
                    ),
                  if (_gameOver)
                    _buildBlockingOverlay(
                      title: 'Game Over',
                      description: 'Bryce ran out of aprons. Try the quest again!',
                      primaryLabel: 'Restart Quest',
                      onPrimary: _restartCampaign,
                      secondaryLabel: 'Back to Title',
                      onSecondary: _returnToTitle,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f172a), Color(0xFF1f2937)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: Colors.black.withOpacity(0.8),
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Bryce's Pizza Quest",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Five themed kitchens. Four essential ingredients per stop. '
                      'Double-jump past rival chefs and hazards to finish Bryce\'s cosmic pie.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _beginQuest,
                      icon: const Icon(Icons.local_pizza),
                      label: const Text('Start Cooking'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Controls: Arrow or WASD to move, Space/Up to double jump, R to restart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    if (_showMenu) {
      return const SizedBox.shrink();
    }

    final level = _levels[_currentLevelIndex];
    final tracker = _currentLevel.tracker;
    final ingredientChips = tracker.ingredients
        .map((ingredient) => _IngredientChip(ingredient: ingredient))
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
              Text(
                level.theme,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HudLabel(
                    icon: Icons.local_pizza,
                    label: 'Lives: ${_livesSystem.remaining}',
                  ),
                  _HudLabel(
                    icon: Icons.double_arrow,
                    label: 'Double Jump: ${_jumpController.canJump || _grounded ? 'Ready' : 'Used'}',
                  ),
                  _HudLabel(
                    icon: Icons.flag,
                    label:
                        'Checkpoint: ${_activeCheckpointIndex >= 0 ? _currentLevel.checkpoints[_activeCheckpointIndex].definition.label : 'Starting Oven'}',
                  ),
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
    String? secondaryLabel,
    VoidCallback? onSecondary,
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
                width: 360,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onPrimary,
                    icon: const Icon(Icons.replay),
                    label: Text(primaryLabel),
                  ),
                  if (secondaryLabel != null && onSecondary != null)
                    OutlinedButton.icon(
                      onPressed: onSecondary,
                      icon: const Icon(Icons.home),
                      label: Text(secondaryLabel),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudLabel extends StatelessWidget {
  const _HudLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.ingredient});

  final IngredientState ingredient;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (ingredient.type) {
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
        ingredient.collected ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
        color: ingredient.collected ? Colors.limeAccent : Colors.white70,
      ),
      backgroundColor: ingredient.collected ? color.withOpacity(0.3) : Colors.white12,
      label: Text('${ingredient.displayName} ${ingredient.collected ? '✓' : '…'}'),
    );
  }
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.level,
    required this.player,
    required this.cameraX,
    required this.exitUnlocked,
    required this.themeLabel,
  });

  final LevelInstance level;
  final Rect player;
  final double cameraX;
  final bool exitUnlocked;
  final String themeLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = _gradientForTheme(themeLabel);
    final background = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), background);

    _drawParallax(canvas, size);

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
      final body = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(body, Paint()..color = const Color(0xFFdc2626));
      final hat = Rect.fromLTWH(rect.left, rect.top - 10, rect.width, 10);
      canvas.drawRect(hat, Paint()..color = const Color(0xFF16a34a));
      final brim = Rect.fromLTWH(rect.left - 4, rect.top - 4, rect.width + 8, 6);
      canvas.drawRect(brim, Paint()..color = Colors.white);
      final stache = Path()
        ..moveTo(rect.center.dx - 10, rect.center.dy + 4)
        ..quadraticBezierTo(rect.center.dx - 4, rect.center.dy + 12, rect.center.dx, rect.center.dy + 4)
        ..quadraticBezierTo(rect.center.dx + 4, rect.center.dy + 12, rect.center.dx + 10, rect.center.dy + 4)
        ..quadraticBezierTo(rect.center.dx, rect.center.dy + 18, rect.center.dx - 10, rect.center.dy + 4);
      canvas.drawPath(stache, Paint()..color = Colors.black);
    }

    for (final checkpoint in level.checkpoints) {
      final flagColor = checkpoint.activated ? const Color(0xFFbef264) : Colors.white38;
      final poleRect = Rect.fromLTWH(
        checkpoint.definition.area.center.dx - 3,
        checkpoint.definition.area.bottom - 50,
        6,
        50,
      );
      canvas.drawRect(poleRect, Paint()..color = Colors.white70);
      final flagPath = Path()
        ..moveTo(poleRect.left + poleRect.width, poleRect.top)
        ..lineTo(poleRect.left + poleRect.width + 26, poleRect.top + 10)
        ..lineTo(poleRect.left + poleRect.width, poleRect.top + 20)
        ..close();
      canvas.drawPath(flagPath, Paint()..color = flagColor);
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

    _drawBryce(canvas, player);

    canvas.restore();
  }

  void _drawBryce(Canvas canvas, Rect rect) {
    final body = RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(10));
    final bodyPaint = Paint()..color = const Color(0xFF38bdf8);
    canvas.drawRRect(body, bodyPaint);

    final hatRect = Rect.fromLTWH(rect.center.dx - 18, rect.top - 12, 36, 12);
    final brimRect = Rect.fromLTWH(rect.center.dx - 22, rect.top - 4, 44, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(brimRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF0f172a),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hatRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF22c55e),
    );

    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(rect.left + 14, rect.center.dy - 6), 4, eyePaint);
    canvas.drawCircle(Offset(rect.right - 14, rect.center.dy - 6), 4, eyePaint);
    canvas.drawCircle(Offset(rect.left + 14, rect.center.dy - 6), 2.3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(rect.right - 14, rect.center.dy - 6), 2.3, Paint()..color = Colors.black);

    final mustache = Path()
      ..moveTo(rect.center.dx - 14, rect.center.dy + 4)
      ..quadraticBezierTo(rect.center.dx - 4, rect.center.dy + 12, rect.center.dx, rect.center.dy + 4)
      ..quadraticBezierTo(rect.center.dx + 4, rect.center.dy + 12, rect.center.dx + 14, rect.center.dy + 4)
      ..lineTo(rect.center.dx + 14, rect.center.dy + 8)
      ..quadraticBezierTo(rect.center.dx, rect.center.dy + 20, rect.center.dx - 14, rect.center.dy + 8)
      ..close();
    canvas.drawPath(mustache, Paint()..color = const Color(0xFF0f172a));
  }

  void _drawParallax(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-cameraX * 0.3, 0);
    final skylinePaint = Paint()..color = Colors.white.withOpacity(0.08);
    for (int i = 0; i < 8; i++) {
      final double x = i * 260.0;
      final double buildingHeight = 80 + (i % 3) * 25;
      final rect = Rect.fromLTWH(x, size.height - buildingHeight - 120, 180, buildingHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), skylinePaint);
    }

    final accentPaint = Paint()..color = Colors.white.withOpacity(0.12);
    for (int i = 0; i < 20; i++) {
      final double x = i * 140.0 + (i.isEven ? 30 : 0);
      final double y = 80 + (i % 5) * 30;
      canvas.drawCircle(Offset(x, y), 2.2, accentPaint);
    }
    canvas.restore();
  }

  List<Color> _gradientForTheme(String label) {
    if (label.contains('Market')) {
      return const [Color(0xFF1a2b4c), Color(0xFF0f172a)];
    }
    if (label.contains('Skyline')) {
      return const [Color(0xFF0f172a), Color(0xFF1e3a5f)];
    }
    if (label.contains('Coastal')) {
      return const [Color(0xFF032c3d), Color(0xFF0a192f)];
    }
    if (label.contains('Cosmic')) {
      return const [Color(0xFF111827), Color(0xFF3b0764)];
    }
    return const [Color(0xFF0f172a), Color(0xFF1f2937)];
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}
