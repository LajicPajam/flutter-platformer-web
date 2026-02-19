import 'dart:ui';

import 'package:flutter_platformer/game_logic.dart';
import 'package:flutter_platformer/level_data.dart';
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
          displayName: 'Test Dough',
        ),
        IngredientState(
          id: 'b',
          type: IngredientType.sauce,
          rect: Rect.zero,
          displayName: 'Test Sauce',
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

  test('level definitions provide five levels with four ingredients each', () {
    final levels = buildLevelDefinitions();
    expect(levels.length, 5);
    for (final level in levels) {
      expect(level.ingredients.length, 4);
    }
  });
}
