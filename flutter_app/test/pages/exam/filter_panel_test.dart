import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/widgets/filter_panel.dart';
import '../../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  group('FilterPanel', () {
    testWidgets('renders year and region chips', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: SingleChildScrollView(child: FilterPanel(yearOptions: ['2025', '2024'], regionOptions: ['海淀', '西城'])),
      )));
      expect(find.text('年份'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('地区'), findsOneWidget);
      expect(find.text('海淀'), findsOneWidget);
      expect(find.text('西城'), findsOneWidget);
    });

    testWidgets('renders concept tags when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: SingleChildScrollView(child: FilterPanel(yearOptions: [], regionOptions: [], conceptTagOptions: ['函数', '三角函数'])),
      )));
      expect(find.text('按概念标签筛选'), findsOneWidget);
      expect(find.text('函数'), findsOneWidget);
      expect(find.text('三角函数'), findsOneWidget);
    });

    testWidgets('renders difficulty segment descriptions', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: FilterPanel(yearOptions: [], regionOptions: []),
      )));
      // 段位标签应存在（难度/计算量覆盖范围的提示）
      expect(find.textContaining('基础'), findsWidgets);
      expect(find.textContaining('压轴'), findsWidgets);
    });
  });
}
