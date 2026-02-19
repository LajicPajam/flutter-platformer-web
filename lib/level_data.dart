import 'dart:ui';

import 'game_logic.dart';

class IngredientDefinition {
  const IngredientDefinition({
    required this.id,
    required this.type,
    required this.rect,
  });

  final String id;
  final IngredientType type;
  final Rect rect;

  IngredientState createState() =>
      IngredientState(id: id, type: type, rect: rect, collected: false);
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.start,
    required this.size,
    required this.speed,
    required this.minX,
    required this.maxX,
  });

  final Offset start;
  final Size size;
  final double speed;
  final double minX;
  final double maxX;

  MovingEnemy createState() => MovingEnemy(
        position: start,
        size: size,
        speed: speed,
        minX: minX,
        maxX: maxX,
      );
}

class MovingEnemy {
  MovingEnemy({
    required this.position,
    required this.size,
    required this.speed,
    required this.minX,
    required this.maxX,
  });

  Offset position;
  final Size size;
  final double speed;
  final double minX;
  final double maxX;
  double _direction = 1;

  Rect get rect => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

  void update(double deltaSeconds) {
    double nextX = position.dx + _direction * speed * deltaSeconds;
    final minAllowed = minX;
    final maxAllowed = maxX - size.width;

    if (nextX <= minAllowed) {
      nextX = minAllowed;
      _direction = 1;
    } else if (nextX >= maxAllowed) {
      nextX = maxAllowed;
      _direction = -1;
    }

    position = Offset(nextX, position.dy);
  }
}

class LevelDefinition {
  const LevelDefinition({
    required this.name,
    required this.worldSize,
    required this.spawn,
    required this.exit,
    required this.platforms,
    required this.hazards,
    required this.ingredients,
    required this.enemies,
  });

  final String name;
  final Size worldSize;
  final Offset spawn;
  final Rect exit;
  final List<Rect> platforms;
  final List<Rect> hazards;
  final List<IngredientDefinition> ingredients;
  final List<EnemyDefinition> enemies;

  LevelInstance createInstance() => LevelInstance(definition: this);
}

class LevelInstance {
  LevelInstance({required this.definition}) {
    resetDynamicState();
  }

  final LevelDefinition definition;
  late List<IngredientState> ingredients;
  late List<MovingEnemy> enemies;
  late IngredientTracker tracker;

  void resetDynamicState() {
    ingredients = definition.ingredients.map((def) => def.createState()).toList();
    enemies = definition.enemies.map((def) => def.createState()).toList();
    tracker = IngredientTracker(ingredients: ingredients);
  }
}

List<LevelDefinition> buildLevelDefinitions() {
  return [
    LevelDefinition(
      name: 'Farmer\'s Market',
      worldSize: const Size(2200, 900),
      spawn: const Offset(60, 680),
      exit: const Rect.fromLTWH(1930, 240, 90, 150),
      platforms: const [
        Rect.fromLTWH(0, 740, 520, 60),
        Rect.fromLTWH(560, 660, 220, 40),
        Rect.fromLTWH(840, 580, 240, 40),
        Rect.fromLTWH(1120, 520, 240, 40),
        Rect.fromLTWH(1400, 460, 200, 40),
        Rect.fromLTWH(1680, 390, 220, 40),
        Rect.fromLTWH(1880, 540, 240, 40),
        Rect.fromLTWH(1180, 780, 420, 40),
        Rect.fromLTWH(1520, 670, 180, 30),
      ],
      hazards: const [
        Rect.fromLTWH(520, 800, 220, 20),
        Rect.fromLTWH(1000, 820, 200, 20),
      ],
      ingredients: const [
        IngredientDefinition(
          id: 'lvl1-dough',
          type: IngredientType.dough,
          rect: Rect.fromLTWH(200, 680, 34, 34),
        ),
        IngredientDefinition(
          id: 'lvl1-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(930, 520, 34, 34),
        ),
      ],
      enemies: const [
        EnemyDefinition(
          start: Offset(1250, 744),
          size: Size(46, 32),
          speed: 110,
          minX: 1180,
          maxX: 1520,
        ),
      ],
    ),
    LevelDefinition(
      name: 'Cheese Caverns',
      worldSize: const Size(2500, 1000),
      spawn: const Offset(80, 760),
      exit: const Rect.fromLTWH(2150, 260, 90, 150),
      platforms: const [
        Rect.fromLTWH(0, 820, 420, 60),
        Rect.fromLTWH(480, 720, 260, 40),
        Rect.fromLTWH(820, 640, 260, 40),
        Rect.fromLTWH(1140, 600, 220, 40),
        Rect.fromLTWH(1400, 520, 220, 40),
        Rect.fromLTWH(1680, 450, 220, 40),
        Rect.fromLTWH(1960, 380, 220, 40),
        Rect.fromLTWH(1700, 780, 420, 40),
        Rect.fromLTWH(2100, 660, 240, 30),
      ],
      hazards: const [
        Rect.fromLTWH(620, 880, 220, 20),
        Rect.fromLTWH(1320, 900, 240, 20),
        Rect.fromLTWH(1880, 900, 240, 20),
      ],
      ingredients: const [
        IngredientDefinition(
          id: 'lvl2-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1480, 540, 34, 34),
        ),
        IngredientDefinition(
          id: 'lvl2-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(1020, 660, 34, 34),
        ),
      ],
      enemies: const [
        EnemyDefinition(
          start: Offset(600, 786),
          size: Size(48, 34),
          speed: 140,
          minX: 520,
          maxX: 840,
        ),
        EnemyDefinition(
          start: Offset(1550, 486),
          size: Size(48, 34),
          speed: 160,
          minX: 1500,
          maxX: 1900,
        ),
      ],
    ),
    LevelDefinition(
      name: 'Topping Tower',
      worldSize: const Size(2800, 1100),
      spawn: const Offset(120, 820),
      exit: const Rect.fromLTWH(2420, 180, 90, 150),
      platforms: const [
        Rect.fromLTWH(0, 880, 520, 60),
        Rect.fromLTWH(580, 780, 220, 40),
        Rect.fromLTWH(880, 700, 220, 40),
        Rect.fromLTWH(1180, 620, 220, 40),
        Rect.fromLTWH(1500, 540, 220, 40),
        Rect.fromLTWH(1820, 460, 220, 40),
        Rect.fromLTWH(2140, 380, 220, 40),
        Rect.fromLTWH(2460, 300, 220, 40),
        Rect.fromLTWH(1300, 880, 420, 40),
        Rect.fromLTWH(1800, 760, 220, 30),
        Rect.fromLTWH(2080, 660, 220, 30),
      ],
      hazards: const [
        Rect.fromLTWH(540, 940, 240, 20),
        Rect.fromLTWH(1200, 960, 240, 20),
        Rect.fromLTWH(1900, 960, 240, 20),
      ],
      ingredients: const [
        IngredientDefinition(
          id: 'lvl3-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1350, 640, 34, 34),
        ),
        IngredientDefinition(
          id: 'lvl3-toppings-a',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(2050, 700, 34, 34),
        ),
        IngredientDefinition(
          id: 'lvl3-toppings-b',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(2320, 420, 34, 34),
        ),
      ],
      enemies: const [
        EnemyDefinition(
          start: Offset(900, 846),
          size: Size(52, 36),
          speed: 180,
          minX: 820,
          maxX: 1200,
        ),
        EnemyDefinition(
          start: Offset(2000, 726),
          size: Size(52, 36),
          speed: 200,
          minX: 1920,
          maxX: 2300,
        ),
      ],
    ),
  ];
}
