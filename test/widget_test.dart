import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_platformer/main.dart';

void main() {
  testWidgets('shows control instructions and canvas', (tester) async {
    await tester.pumpWidget(const PlatformerApp());

    expect(find.textContaining('Reach the glowing portal'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
