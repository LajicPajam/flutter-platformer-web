import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_platformer/main.dart';

void main() {
  testWidgets('home screen shows title and starts game', (tester) async {
    await tester.pumpWidget(const PlatformerApp());

    expect(find.text("Bryce's Pizza Quest"), findsOneWidget);
    final playButton = find.text('Start Cooking');
    expect(playButton, findsOneWidget);

    await tester.tap(playButton);
    await tester.pump();

    expect(find.textContaining('Level 1/5'), findsOneWidget);
    expect(find.textContaining('Checkpoint: Starting Oven'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
