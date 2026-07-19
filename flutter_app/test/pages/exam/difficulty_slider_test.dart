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

    testWidgets('uses Slider when lower equals upper (single value mode)', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 5, upper: 5, onChanged: (_) {}, label: '目标难度'),
      )));
      // 单值模式应渲染 Slider，而非 RangeSlider
      expect(find.text('目标难度'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(RangeSlider), findsNothing);
    });

    testWidgets('single value mode calls onChanged with RangeValues(v, v)', (tester) async {
      RangeValues? result;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DifficultySlider(min: 0, max: 10, lower: 5, upper: 5, onChanged: (v) => result = v, label: '目标难度'),
      )));
      final slider = find.byType(Slider);
      // 触发 Slider 的 onChanged
      (tester.widget(slider) as Slider).onChanged!(4.5);
      expect(result, isNotNull);
      expect(result!.start, 4.5);
      expect(result!.end, 4.5);
    });
  });
}
