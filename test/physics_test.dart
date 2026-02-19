import 'package:flutter_platformer/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gravity respects terminal velocity', () {
    final velocity = applyGravity(
      currentVelocity: 800,
      gravity: 400,
      deltaSeconds: 0.5,
      terminalVelocity: 900,
    );

    expect(velocity, 900);
  });

  test('camera offset stays within level bounds', () {
    final offset = clampCameraOffset(
      playerCenter: 50,
      viewportWidth: 400,
      levelWidth: 1000,
    );

    expect(offset, 0);

    final farOffset = clampCameraOffset(
      playerCenter: 950,
      viewportWidth: 400,
      levelWidth: 1000,
    );

    expect(farOffset, closeTo(600, 0.001));
  });
}
