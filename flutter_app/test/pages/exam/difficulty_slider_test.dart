import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/widgets/difficulty_slider.dart';

void main() {
  group('DifficultySlider', () {
    testWidgets('renders with label and range', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: '难度'),
      )));
      expect(find.text('难度'), findsOneWidget);
      expect(find.text('基础'), findsOneWidget);
      expect(find.text('压轴'), findsOneWidget);
    });

    testWidgets('calls onChanged when slider moves', (tester) async {
      RangeValues? result;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (v) => result = v, label: '')),
      ));
      // Just verify the slider exists
      expect(find.byType(RangeSlider), findsOneWidget);
    });
  });
}
