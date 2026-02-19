import 'dart:ui';

import 'package:flutter_platformer/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('double jump allows only two jumps until reset', () {
    final controller = DoubleJumpController(maxJumps: 2);

    expect(controller.canJump, isTrue);
    controller.registerJump();
    expect(controller.canJump, isTrue);
    controller.registerJump();
    expect(controller.canJump, isFalse);

    controller.reset();
    expect(controller.canJump, isTrue);
  });

  test('ingredient tracker reports completion only when all collected', () {
    final tracker = IngredientTracker(
      ingredients: [
        IngredientState(
          id: 'a',
          type: IngredientType.dough,
          rect: Rect.zero,
        ),
        IngredientState(
          id: 'b',
          type: IngredientType.sauce,
          rect: Rect.zero,
        ),
      ],
    );

    expect(tracker.isComplete, isFalse);
    tracker.ingredients.first.collected = true;
    expect(tracker.isComplete, isFalse);
    tracker.ingredients.last.collected = true;
    expect(tracker.isComplete, isTrue);
  });

  test('lives system triggers game over when reaching zero', () {
    final lives = LivesSystem(maxLives: 2);

    expect(lives.remaining, 2);
    expect(lives.loseLife(), isFalse);
    expect(lives.remaining, 1);
    expect(lives.loseLife(), isTrue);
    expect(lives.remaining, 0);
  });
}
