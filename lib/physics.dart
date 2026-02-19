import 'dart:math' as math;

/// Applies gravity to the current vertical velocity and enforces a
/// terminal fall speed to keep the simulation stable on the web.
double applyGravity({
  required double currentVelocity,
  required double gravity,
  required double deltaSeconds,
  required double terminalVelocity,
}) {
  final updated = currentVelocity + gravity * deltaSeconds;
  return math.min(updated, terminalVelocity);
}

/// Computes the camera offset so that the player stays close to the
/// center of the viewport while remaining within the level bounds.
double clampCameraOffset({
  required double playerCenter,
  required double viewportWidth,
  required double levelWidth,
}) {
  final maxOffset = math.max(0.0, levelWidth - viewportWidth);
  final target = playerCenter - viewportWidth / 2;
  if (target < 0) {
    return 0;
  }
  if (target > maxOffset) {
    return maxOffset;
  }
  return target;
}
