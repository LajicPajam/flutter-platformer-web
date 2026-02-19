# Bryce's Pizza Quest (Flutter Web Platformer)

Bryce is on a mission to bake the most legendary pizza in the quadrant. Each of the five themed kitchen levels hides fresh ingredients — dough, sauce, cheese, and a signature topping — guarded by rival Italian chefs and precarious floating platforms. Guide Bryce through every stage, collect the set of four ingredients, dodge hazards, and vault into the glowing portal once the recipe is complete.

## Prerequisites
- Flutter SDK 3.24+ with web support enabled (`flutter config --enable-web`).
- Google Chrome or Chromium for running via `flutter run -d chrome`.
- Run `flutter doctor` after installing to verify the toolchain.

## Setup
```bash
cd /home/lajicpajam/projects/flutter-platformer
flutter pub get
```
If Chrome is unavailable on the host, you can temporarily target the web-server device (`flutter run -d web-server`).

## Running the Game
```bash
flutter run -d chrome
```
You will see a title screen — click **Start Cooking** (or press Space/Enter) to begin Bryce's quest.

### Controls
- **Move**: Arrow keys or `A`/`D`
- **Jump / Double Jump**: Arrow Up, `W`, or Space. Bryce can jump twice before landing.
- **Restart Quest**: Press `R` from the victory/game-over overlays or use the on-screen buttons.

Collect **all four ingredients** in a level (Dough, Sauce, Cheese, Unique Topping) to light up the exit portal. Hazards (red spikes) and patrolling Italian rival chefs will cost Bryce a life. Falling off the map also counts as a death. Bryce starts each run with **three lives** and can tag mid-level checkpoints; on a fall, he respawns from the latest oven he activated instead of restarting the entire map.

### Kitchen Tour
1. **Home Oven Heights** – Cozy rooftops where Bryce grabs stone-milled dough and grandma sauce.
2. **Midtown Market** – Neon-lit produce stalls hiding truffle oil.
3. **Skyline Rooftop** – Windy scaffolding with lightning basil pickups.
4. **Coastal Kitchen** – Salt-sprayed boardwalk ovens and anchovy crumble.
5. **Cosmic Pizzeria** – Zero-G platforms full of meteor dough and galaxy basil dust.

Each level has unique platform layouts, hazards, rival chefs, and checkpoint flags. A parallax skyline/background gives every kitchen its own vibe, and the HUD shows the current level, theme, lives, double-jump state, checkpoint label, and ingredient checklist.

## Building for the Web
```bash
flutter build web
```
Artifacts land in `build/web/` for static hosting.

## Testing
Logic and widget tests cover gravity helpers, camera math, ingredient tracking, double-jump limits, HUD/menu rendering, and lives logic:
```bash
flutter test
```
Latest CI evidence for the rework lives under `workspace/shared/logs/task-20260219-015245-rework/03-build/flutter-test.log`.

## Project Structure
```
flutter-platformer/
├── lib/
│   ├── main.dart          # Game loop, HUD, home/victory screens
│   ├── level_data.dart    # Five themed level definitions
│   ├── game_logic.dart    # Ingredient tracker, double jump, lives
│   └── physics.dart       # Gravity + camera helpers
├── test/
│   ├── game_logic_test.dart
│   ├── physics_test.dart
│   └── widget_test.dart
├── web/ ...               # Flutter web bootstrap files
├── README.md
└── pubspec.yaml
```

## Workflow
- Feature work happens on task-specific branches (e.g., `feature/task-20260219-015245`).
- Always run `flutter test` and capture logs inside `workspace/shared/logs/task-20260219-015245-rework/03-build/` before requesting review.
- After review, merge to `main` and push to the GitHub remote (`flutter-platformer-web`).
