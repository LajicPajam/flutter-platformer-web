import 'dart:ui';

enum IngredientType { dough, sauce, cheese, toppings }

String ingredientLabel(IngredientType type) {
  switch (type) {
    case IngredientType.dough:
      return 'Dough';
    case IngredientType.sauce:
      return 'Sauce';
    case IngredientType.cheese:
      return 'Cheese';
    case IngredientType.toppings:
      return 'Toppings';
  }
}

class IngredientState {
  IngredientState({
    required this.id,
    required this.type,
    required this.rect,
    this.collected = false,
  });

  final String id;
  final IngredientType type;
  final Rect rect;
  bool collected;
}

class IngredientTracker {
  IngredientTracker({required List<IngredientState> ingredients})
      : _ingredients = ingredients;

  final List<IngredientState> _ingredients;

  List<IngredientState> get ingredients => _ingredients;

  bool get isComplete => _ingredients.every((item) => item.collected);

  void reset() {
    for (final ingredient in _ingredients) {
      ingredient.collected = false;
    }
  }

  Map<IngredientType, bool> statusByType() {
    final Map<IngredientType, bool> status = {};
    for (final ingredient in _ingredients) {
      status[ingredient.type] =
          (status[ingredient.type] ?? true) && ingredient.collected;
    }
    return status;
  }
}

class DoubleJumpController {
  DoubleJumpController({this.maxJumps = 2});

  final int maxJumps;
  int _jumpsUsed = 0;

  bool get canJump => _jumpsUsed < maxJumps;

  void registerJump() {
    if (canJump) {
      _jumpsUsed += 1;
    }
  }

  void reset() {
    _jumpsUsed = 0;
  }
}

class LivesSystem {
  LivesSystem({this.maxLives = 3}) : _lives = maxLives;

  final int maxLives;
  int _lives;

  int get remaining => _lives;

  bool loseLife() {
    if (_lives > 0) {
      _lives -= 1;
    }
    return _lives <= 0;
  }

  void reset() {
    _lives = maxLives;
  }
}
