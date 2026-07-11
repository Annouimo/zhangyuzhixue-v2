import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/widgets/difficulty_slider.dart';

void main() {
  group('DifficultySlider', () {
    testWidgets('default label uses difficulty breaks', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: '难度范围'),
      )));
      expect(find.text('基础'), findsOneWidget);
      expect(find.text('压轴'), findsOneWidget);
      // Difficulty label should not show calculation labels
      expect(find.text('少量'), findsNothing);
    });

    testWidgets('calculation label uses calculation breaks', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: '计算量范围'),
      )));
      expect(find.text('少量'), findsOneWidget);
      expect(find.text('繁琐'), findsOneWidget);
      // Calculation label should not show difficulty labels
      expect(find.text('基础'), findsNothing);
    });

    testWidgets('calls onChanged', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: ''),
      )));
      expect(find.byType(RangeSlider), findsOneWidget);
    });
  });
}
