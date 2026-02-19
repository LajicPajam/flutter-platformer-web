import 'dart:ui';

import 'game_logic.dart';

class IngredientDefinition {
  const IngredientDefinition({
    required this.id,
    required this.type,
    required this.rect,
    required this.displayName,
  });

  final String id;
  final IngredientType type;
  final Rect rect;
  final String displayName;

  IngredientState createState() => IngredientState(
        id: id,
        type: type,
        rect: rect,
        displayName: displayName,
        collected: false,
      );
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

class CheckpointDefinition {
  const CheckpointDefinition({
    required this.area,
    required this.respawn,
    required this.label,
  });

  final Rect area;
  final Offset respawn;
  final String label;

  CheckpointState createState() => CheckpointState(definition: this);
}

class CheckpointState {
  CheckpointState({required this.definition});

  final CheckpointDefinition definition;
  bool activated = false;
}

class LevelDefinition {
  const LevelDefinition({
    required this.name,
    required this.theme,
    required this.worldSize,
    required this.spawn,
    required this.exit,
    required this.platforms,
    required this.hazards,
    required this.ingredients,
    required this.enemies,
    required this.checkpoints,
  });

  final String name;
  final String theme;
  final Size worldSize;
  final Offset spawn;
  final Rect exit;
  final List<Rect> platforms;
  final List<Rect> hazards;
  final List<IngredientDefinition> ingredients;
  final List<EnemyDefinition> enemies;
  final List<CheckpointDefinition> checkpoints;

  LevelInstance createInstance() => LevelInstance(definition: this);
}

class LevelInstance {
  LevelInstance({required this.definition}) {
    ingredients = definition.ingredients.map((def) => def.createState()).toList();
    tracker = IngredientTracker(ingredients: ingredients);
    enemies = definition.enemies.map((def) => def.createState()).toList();
    checkpoints = definition.checkpoints.map((def) => def.createState()).toList();
  }

  final LevelDefinition definition;
  late List<IngredientState> ingredients;
  late List<MovingEnemy> enemies;
  late IngredientTracker tracker;
  late List<CheckpointState> checkpoints;

  void resetDynamicState({bool full = true}) {
    enemies = definition.enemies.map((def) => def.createState()).toList();
    if (full) {
      ingredients = definition.ingredients.map((def) => def.createState()).toList();
      tracker = IngredientTracker(ingredients: ingredients);
      checkpoints = definition.checkpoints.map((def) => def.createState()).toList();
    }
  }
}

List<LevelDefinition> buildLevelDefinitions() {
  return [
    LevelDefinition(
      name: 'Home Oven Heights',
      theme: 'Cozy Brooklyn kitchen rooftops',
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
          displayName: 'Stone-Milled Dough',
        ),
        IngredientDefinition(
          id: 'lvl1-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(930, 520, 34, 34),
          displayName: 'Grandma Sauce',
        ),
        IngredientDefinition(
          id: 'lvl1-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1410, 420, 34, 34),
          displayName: 'Fresh Mozzarella',
        ),
        IngredientDefinition(
          id: 'lvl1-top',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(1820, 350, 34, 34),
          displayName: 'Rooftop Basil',
        ),
      ],
      enemies: const [
        EnemyDefinition(
          start: Offset(1250, 744),
          size: Size(46, 32),
          speed: 120,
          minX: 1180,
          maxX: 1520,
        ),
      ],
      checkpoints: const [
        CheckpointDefinition(
          area: Rect.fromLTWH(620, 640, 60, 80),
          respawn: Offset(620, 620),
          label: 'Brick Oven A',
        ),
        CheckpointDefinition(
          area: Rect.fromLTWH(1500, 420, 80, 80),
          respawn: Offset(1500, 420),
          label: 'Basil Garden',
        ),
      ],
    ),
    LevelDefinition(
      name: 'Midtown Market',
      theme: 'Bustling produce stands and neon signs',
      worldSize: const Size(2400, 960),
      spawn: const Offset(80, 760),
      exit: const Rect.fromLTWH(2050, 300, 90, 150),
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
          id: 'lvl2-dough',
          type: IngredientType.dough,
          rect: Rect.fromLTWH(160, 760, 34, 34),
          displayName: 'Market Dough',
        ),
        IngredientDefinition(
          id: 'lvl2-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(1020, 660, 34, 34),
          displayName: 'Fire-Roasted Sauce',
        ),
        IngredientDefinition(
          id: 'lvl2-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1480, 540, 34, 34),
          displayName: 'Sharp Provolone',
        ),
        IngredientDefinition(
          id: 'lvl2-top',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(1860, 420, 34, 34),
          displayName: 'Truffle Oil',
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
      checkpoints: const [
        CheckpointDefinition(
          area: Rect.fromLTWH(850, 600, 80, 80),
          respawn: Offset(860, 600),
          label: 'Neon Cart',
        ),
        CheckpointDefinition(
          area: Rect.fromLTWH(1800, 420, 80, 80),
          respawn: Offset(1810, 420),
          label: 'Spice Stall',
        ),
      ],
    ),
    LevelDefinition(
      name: 'Skyline Rooftop',
      theme: 'Windy scaffolding high above the skyline',
      worldSize: const Size(2600, 1000),
      spawn: const Offset(120, 820),
      exit: const Rect.fromLTWH(2200, 260, 90, 150),
      platforms: const [
        Rect.fromLTWH(0, 880, 520, 60),
        Rect.fromLTWH(580, 780, 220, 40),
        Rect.fromLTWH(880, 700, 220, 40),
        Rect.fromLTWH(1180, 620, 220, 40),
        Rect.fromLTWH(1500, 540, 220, 40),
        Rect.fromLTWH(1820, 460, 220, 40),
        Rect.fromLTWH(2140, 380, 220, 40),
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
          id: 'lvl3-dough',
          type: IngredientType.dough,
          rect: Rect.fromLTWH(360, 820, 34, 34),
          displayName: 'Airy Ciabatta Dough',
        ),
        IngredientDefinition(
          id: 'lvl3-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(1040, 640, 34, 34),
          displayName: 'Sun-Dried Sauce',
        ),
        IngredientDefinition(
          id: 'lvl3-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1350, 640, 34, 34),
          displayName: 'Cloud Ricotta',
        ),
        IngredientDefinition(
          id: 'lvl3-top',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(2050, 700, 34, 34),
          displayName: 'Lightning Basil',
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
      checkpoints: const [
        CheckpointDefinition(
          area: Rect.fromLTWH(1180, 580, 80, 80),
          respawn: Offset(1190, 580),
          label: 'Sky Kitchen Lift',
        ),
        CheckpointDefinition(
          area: Rect.fromLTWH(1980, 660, 80, 80),
          respawn: Offset(1990, 660),
          label: 'Windmill Bench',
        ),
      ],
    ),
    LevelDefinition(
      name: 'Coastal Kitchen',
      theme: 'Salt-sprayed boardwalk ovens',
      worldSize: const Size(2700, 1100),
      spawn: const Offset(100, 880),
      exit: const Rect.fromLTWH(2380, 320, 90, 150),
      platforms: const [
        Rect.fromLTWH(0, 940, 540, 60),
        Rect.fromLTWH(620, 840, 220, 40),
        Rect.fromLTWH(920, 780, 220, 40),
        Rect.fromLTWH(1240, 700, 240, 40),
        Rect.fromLTWH(1520, 620, 240, 40),
        Rect.fromLTWH(1800, 540, 240, 40),
        Rect.fromLTWH(2080, 460, 240, 40),
        Rect.fromLTWH(2360, 380, 240, 40),
        Rect.fromLTWH(1500, 900, 420, 40),
      ],
      hazards: const [
        Rect.fromLTWH(560, 1010, 220, 20),
        Rect.fromLTWH(1200, 1030, 240, 20),
        Rect.fromLTWH(1960, 1030, 240, 20),
      ],
      ingredients: const [
        IngredientDefinition(
          id: 'lvl4-dough',
          type: IngredientType.dough,
          rect: Rect.fromLTWH(260, 900, 34, 34),
          displayName: 'Sea Salt Dough',
        ),
        IngredientDefinition(
          id: 'lvl4-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(960, 760, 34, 34),
          displayName: 'Garlic Tide Sauce',
        ),
        IngredientDefinition(
          id: 'lvl4-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1580, 660, 34, 34),
          displayName: 'Smoked Scamorza',
        ),
        IngredientDefinition(
          id: 'lvl4-top',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(2160, 500, 34, 34),
          displayName: 'Lemon Anchovy Crumble',
        ),
      ],
      enemies: const [
        EnemyDefinition(
          start: Offset(700, 906),
          size: Size(52, 36),
          speed: 160,
          minX: 640,
          maxX: 960,
        ),
        EnemyDefinition(
          start: Offset(1780, 586),
          size: Size(52, 36),
          speed: 180,
          minX: 1700,
          maxX: 2100,
        ),
      ],
      checkpoints: const [
        CheckpointDefinition(
          area: Rect.fromLTWH(1100, 720, 80, 80),
          respawn: Offset(1110, 720),
          label: 'Pier Oven',
        ),
        CheckpointDefinition(
          area: Rect.fromLTWH(2100, 500, 80, 80),
          respawn: Offset(2110, 500),
          label: 'Boardwalk Grill',
        ),
      ],
    ),
    LevelDefinition(
      name: 'Cosmic Pizzeria',
      theme: 'Zero-G kitchen orbiting the city',
      worldSize: const Size(3000, 1200),
      spawn: const Offset(140, 920),
      exit: const Rect.fromLTWH(2600, 200, 120, 160),
      platforms: const [
        Rect.fromLTWH(0, 980, 560, 60),
        Rect.fromLTWH(660, 880, 260, 40),
        Rect.fromLTWH(980, 780, 260, 40),
        Rect.fromLTWH(1320, 700, 260, 40),
        Rect.fromLTWH(1660, 620, 260, 40),
        Rect.fromLTWH(2000, 540, 260, 40),
        Rect.fromLTWH(2340, 460, 260, 40),
        Rect.fromLTWH(2680, 380, 260, 40),
        Rect.fromLTWH(1500, 980, 460, 40),
        Rect.fromLTWH(1960, 860, 240, 30),
      ],
      hazards: const [
        Rect.fromLTWH(580, 1050, 220, 20),
        Rect.fromLTWH(1400, 1080, 240, 20),
        Rect.fromLTWH(2200, 1080, 240, 20),
      ],
      ingredients: const [
        IngredientDefinition(
          id: 'lvl5-dough',
          type: IngredientType.dough,
          rect: Rect.fromLTWH(320, 930, 34, 34),
          displayName: 'Meteor Dough',
        ),
        IngredientDefinition(
          id: 'lvl5-sauce',
          type: IngredientType.sauce,
          rect: Rect.fromLTWH(1180, 760, 34, 34),
          displayName: 'Nebula Sauce',
        ),
        IngredientDefinition(
          id: 'lvl5-cheese',
          type: IngredientType.cheese,
          rect: Rect.fromLTWH(1820, 640, 34, 34),
          displayName: 'Starlight Burrata',
        ),
        IngredientDefinition(
          id: 'lvl5-top',
          type: IngredientType.toppings,
          rect: Rect.fromLTWH(2500, 420, 34, 34),
          displayName: 'Galaxy Basil Dust',
        ),
      ],
      enemies: const [
        EnemyDefinition(
          start: Offset(900, 946),
          size: Size(56, 36),
          speed: 190,
          minX: 840,
          maxX: 1180,
        ),
        EnemyDefinition(
          start: Offset(2100, 506),
          size: Size(56, 36),
          speed: 210,
          minX: 2000,
          maxX: 2500,
        ),
        EnemyDefinition(
          start: Offset(2400, 846),
          size: Size(56, 36),
          speed: 220,
          minX: 2320,
          maxX: 2700,
        ),
      ],
      checkpoints: const [
        CheckpointDefinition(
          area: Rect.fromLTWH(1500, 940, 120, 80),
          respawn: Offset(1510, 940),
          label: 'Orbital Forge',
        ),
        CheckpointDefinition(
          area: Rect.fromLTWH(2350, 460, 100, 80),
          respawn: Offset(2360, 460),
          label: 'Starlight Counter',
        ),
      ],
    ),
  ];
}
