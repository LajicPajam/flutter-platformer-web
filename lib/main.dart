import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'physics.dart';

void main() {
  runApp(const PlatformerApp());
}

class PlatformerApp extends StatelessWidget {
  const PlatformerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Platformer',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
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
  static const Size _levelSize = Size(2200, 900);
  static const Rect _goalArea = Rect.fromLTWH(1930, 240, 80, 140);
  static const double _moveSpeed = 260;
  static const double _jumpVelocity = -620;
  static const double _gravity = 1800;
  static const double _terminalVelocity = 900;

  final List<Rect> _platforms = const [
    Rect.fromLTWH(0, 740, 500, 60),
    Rect.fromLTWH(520, 660, 220, 40),
    Rect.fromLTWH(800, 580, 220, 40),
    Rect.fromLTWH(1090, 520, 240, 40),
    Rect.fromLTWH(1380, 460, 200, 40),
    Rect.fromLTWH(1660, 380, 200, 40),
    Rect.fromLTWH(1880, 540, 240, 40),
    Rect.fromLTWH(1180, 780, 420, 40),
    Rect.fromLTWH(1520, 670, 180, 30),
  ];

  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();
  Duration? _lastTick;
  Size? _viewportSize;

  Offset _playerPosition = const Offset(60, 680);
  double _velocityX = 0;
  double _velocityY = 0;
  double _cameraX = 0;
  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _grounded = false;
  bool _won = false;

  Rect get _playerRect => Rect.fromLTWH(
        _playerPosition.dx,
        _playerPosition.dy,
        _playerSize.width,
        _playerSize.height,
      );

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _ticker = createTicker(_handleTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTick(Duration elapsed) {
    if (_viewportSize == null || _won) {
      _lastTick = elapsed;
      return;
    }

    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) {
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

    _moveHorizontally(delta);
    _moveVertically(delta);
    _updateCamera();
    _checkGoalReached();

    if (mounted) {
      setState(() {});
    }
  }

  void _moveHorizontally(double delta) {
    if (_velocityX == 0) {
      return;
    }
    double nextX = _playerPosition.dx + _velocityX * delta;
    Rect future = Rect.fromLTWH(nextX, _playerPosition.dy, _playerSize.width, _playerSize.height);

    for (final platform in _platforms) {
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

    nextX = nextX.clamp(0.0, _levelSize.width - _playerSize.width);
    _playerPosition = Offset(nextX, _playerPosition.dy);
  }

  void _moveVertically(double delta) {
    double nextY = _playerPosition.dy + _velocityY * delta;
    Rect future = Rect.fromLTWH(_playerPosition.dx, nextY, _playerSize.width, _playerSize.height);
    bool grounded = false;

    for (final platform in _platforms) {
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
      nextY.clamp(0.0, _levelSize.height - _playerSize.height),
    );
    _grounded = grounded;

    if (_playerPosition.dy > _levelSize.height + 200) {
      _respawn();
    }
  }

  void _checkGoalReached() {
    if (!_won && _playerRect.overlaps(_goalArea)) {
      setState(() {
        _won = true;
      });
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
      levelWidth: _levelSize.width,
    );
  }

  void _respawn() {
    _playerPosition = const Offset(60, 680);
    _velocityX = 0;
    _velocityY = 0;
    _grounded = false;
    _won = false;
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.repeat) {
      return;
    }

    final isDown = event is RawKeyDownEvent;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _leftPressed = isDown;
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _rightPressed = isDown;
    }

    if (isDown &&
        (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.keyW)) {
      _jump();
    }
  }

  void _jump() {
    if (_grounded && !_won) {
      _velocityY = _jumpVelocity;
      _grounded = false;
    }
  }

  void _restartLevel() {
    setState(() {
      _respawn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
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
                    painter: GamePainter(
                      platforms: _platforms,
                      goal: _goalArea,
                      player: _playerRect,
                      cameraX: _cameraX,
                      levelSize: _levelSize,
                      won: _won,
                    ),
                    size: Size.infinite,
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Use Arrow keys or WASD to move. Space/Up to jump.\n'
                          'Reach the glowing portal to win.',
                        ),
                      ),
                    ),
                  ),
                  if (_won)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Level Complete!',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _restartLevel,
                              icon: const Icon(Icons.replay),
                              label: const Text('Restart'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.platforms,
    required this.goal,
    required this.player,
    required this.cameraX,
    required this.levelSize,
    required this.won,
  });

  final List<Rect> platforms;
  final Rect goal;
  final Rect player;
  final double cameraX;
  final Size levelSize;
  final bool won;

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

    for (final platform in platforms) {
      final rrect = RRect.fromRectAndRadius(platform, const Radius.circular(6));
      canvas.drawRRect(rrect, platformPaint);
      canvas.drawRRect(rrect, edgePaint);
    }

    final goalPaint = Paint()
      ..color = won ? const Color(0xFFbef264) : const Color(0xFFfacc15);
    final goalOutline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final goalRRect = RRect.fromRectAndRadius(goal, const Radius.circular(8));
    canvas.drawRRect(goalRRect, goalPaint);
    canvas.drawRRect(goalRRect, goalOutline);

    final playerPaint = Paint()
      ..color = won ? const Color(0xFF22c55e) : const Color(0xFF38bdf8);
    final playerRRect = RRect.fromRectAndRadius(player, const Radius.circular(8));
    canvas.drawRRect(playerRRect, playerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return oldDelegate.player != player ||
        oldDelegate.cameraX != cameraX ||
        oldDelegate.won != won;
  }
}
