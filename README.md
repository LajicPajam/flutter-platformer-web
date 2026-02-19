# Bryce's Pizza Quest (Flutter Web Platformer)

Bryce is on a mission to bake the most legendary pizza in the quadrant. Each level hides fresh ingredients — dough, sauce, cheese, and toppings — guarded by rival chefs and precarious floating platforms. Guide Bryce through three handcrafted stages, collect every ingredient, dodge hazards, and vault into the glowing portal once the recipe is complete.

## Prerequisites
- Flutter SDK 3.24+ with web support enabled (`flutter config --enable-web`).
- Google Chrome or Chromium for running via `flutter run -d chrome`.
- Dart is bundled with Flutter; run `flutter doctor` after installing to verify the toolchain.

## Setup
```bash
cd /home/lajicpajam/projects/flutter-platformer
flutter pub get
```
If this is a new machine, run `flutter doctor` and follow any prompts. On a server without Chrome you can temporarily use the web-server device (`flutter run -d web-server`).

## Running the Game
```bash
flutter run -d chrome
```
This launches the Flutter web build with hot-reload support.

### Controls
- **Move**: Arrow keys or `A`/`D`
- **Jump / Double Jump**: Arrow Up, `W`, or Space. Bryce can jump twice before landing.
- **Restart Quest**: Press `R` on the victory/game-over screens or click the on-screen button.

Collect every ingredient in the current level to light up the exit portal. Hazards (red spikes) and patrolling rival chefs will cost Bryce a life. Falling off the map also counts as a death.

### Levels & Ingredients
1. **Farmer's Market** – Scoop up Dough & Sauce while learning the ropes.
2. **Cheese Caverns** – Sticky cave walls, faster enemies, Cheese & Sauce pickups.
3. **Topping Tower** – Vertical gauntlet packed with topping crates; finish all tasks to complete the pizza.

Bryce starts with **three lives**. Losing all lives triggers a game-over screen; ingredients reset on each death or level restart.

## Building for the Web
```bash
flutter build web
```
Artifacts are emitted to `build/web/` for static hosting.

## Testing
Logic and widget tests cover gravity helpers, camera math, ingredient tracking, double jump limits, and HUD rendering:
```bash
flutter test
```
Latest test logs for this task are saved under `workspace/shared/logs/task-20260219-015245/03-build/flutter-test.log`.

## Project Structure
```
flutter-platformer/
├── lib/
│   ├── main.dart          # Game loop, rendering, HUD overlays
│   ├── level_data.dart    # Level definitions, hazards, enemies, ingredients
│   ├── game_logic.dart    # Double jump, lives, ingredient trackers
│   └── physics.dart       # Gravity + camera helpers
├── test/
│   ├── game_logic_test.dart
│   ├── physics_test.dart
│   └── widget_test.dart
├── web/ ...               # Flutter web bootstrap files
├── README.md
└── pubspec.yaml
```

## Development Workflow
- Feature work occurs on dedicated branches (e.g., `feature/task-20260219-015245`).
- Always run `flutter test` before review; capture command output in the shared logs directory for traceability.
- After review/approval, merge to `main` and push to the GitHub remote (`flutter-platformer-web`).
