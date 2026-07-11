import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/widgets/filter_panel.dart';

void main() {
  group('FilterPanel', () {
    testWidgets('renders year and region chips', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: FilterPanel(yearOptions: ['2025', '2024'], regionOptions: ['海淀', '西城']),
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
        body: FilterPanel(yearOptions: [], regionOptions: [], conceptTagOptions: ['函数', '三角函数']),
      )));
      expect(find.text('概念标签'), findsOneWidget);
      expect(find.text('函数'), findsOneWidget);
      expect(find.text('三角函数'), findsOneWidget);
    });

    testWidgets('renders type chips', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: FilterPanel(yearOptions: [], regionOptions: []),
      )));
      expect(find.text('选择题'), findsOneWidget);
      expect(find.text('填空题'), findsOneWidget);
      expect(find.text('解答题'), findsOneWidget);
    });
  });
}
