import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_platformer/main.dart';

void main() {
  testWidgets('shows Bryce hud and canvas', (tester) async {
    await tester.pumpWidget(const PlatformerApp());

    expect(find.textContaining("Bryce's Pizza Quest"), findsWidgets);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
