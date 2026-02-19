# Flutter Platformer (Web)

A minimalist 2D platformer built with Flutter for the web. The player is a glowing cube that can run, jump, and traverse a short level of floating platforms to reach a portal. The project demonstrates keyboard input handling, gravity, collision detection, a basic camera, and a win overlay — all rendered with stock Flutter widgets and `CustomPaint`.

## Prerequisites
- Flutter SDK 3.24+ with web support enabled (`flutter config --enable-web`).
- Chrome (or Chromium) installed for running `flutter run -d chrome`.
- A recent version of Dart (bundled with Flutter).

> Tip: run `flutter doctor` after installing the SDK to verify the toolchain and Chrome device detection.

## Setup
```bash
cd /home/lajicpajam/projects/flutter-platformer
flutter pub get
```
If this is a fresh Flutter install, also run `flutter doctor` and follow any prompts to complete the setup.

## Running the Game
```bash
flutter run -d chrome
```
This launches the web build in Chrome. If Chrome is not detected, you can temporarily use the web server device (`flutter run -d web-server`) while installing Chrome.

### Controls
- **Move**: Arrow keys or `A`/`D`
- **Jump**: Arrow Up, `W`, or Spacebar
- **Goal**: Reach the glowing portal at the far right of the level.
- **Restart**: After winning, click the **Restart** button to respawn at the start.

The play area automatically grabs focus; click anywhere in the canvas if the controls stop responding (e.g., after switching tabs).

## Building for the Web
```bash
flutter build web
```
The optimized assets will be placed in `build/web/`.

## Testing
Widget and logic tests are included for the renderer and physics helpers:
```bash
flutter test
```
Latest test output is captured in `workspace/shared/logs/task-20260219-014520/03-build/flutter-test.log`.

## Project Structure
```
flutter-platformer/
├── lib/
│   ├── main.dart          # Game loop, rendering, controls
│   └── physics.dart       # Shared helpers (gravity & camera)
├── test/
│   ├── physics_test.dart  # Gravity/camera unit tests
│   └── widget_test.dart   # Ensures the game widget renders
├── web/                   # Default Flutter web bootstrap files
├── README.md
└── pubspec.yaml
```

## Level Overview
- A starting platform and a handful of staggered floating platforms guide the player upward.
- Gravity, grounded checks, and collision resolution keep the avatar aligned to platform surfaces.
- A portal (yellow/green) sitting above the final ledge marks the win condition; a celebratory overlay appears and freezes movement until restart.

## Workflow Notes
This repository follows the Researcher → Lead → Builder → Reviewer workflow. All feature work happens on dedicated branches, with `flutter test` serving as the minimal CI gate before a change is ready for review.
