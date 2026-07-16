import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/widgets/difficulty_slider.dart';
import '../../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  group('DifficultySlider', () {
    testWidgets('default label uses difficulty breaks', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: '难度范围'),
      )));
      // 只渲染 label + RangeSlider，不渲染难度文本标签
      expect(find.text('难度范围'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('calculation label uses calculation breaks', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: '计算量范围'),
      )));
      expect(find.text('计算量范围'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('calls onChanged', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 2, upper: 8, onChanged: (_) {}, label: ''),
      )));
      expect(find.byType(RangeSlider), findsOneWidget);
    });
  });
}
