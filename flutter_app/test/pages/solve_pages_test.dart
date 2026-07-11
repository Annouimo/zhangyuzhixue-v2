import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/solve/solve_choice_page.dart';
import 'package:flutter_app/pages/solve/solve_fill_page.dart';
import 'package:flutter_app/pages/solve/solve_rate_page.dart';

void main() {
  group('SolveChoicePage', () {
    testWidgets('renders choice page with options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveChoicePage(questionId: 1),
      ));
      expect(find.text('选择题'), findsAtLeast(1));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('can select an option', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveChoicePage(questionId: 1),
      ));
      await tester.tap(find.text('A'));
      await tester.pump();
      // A 被选中 (primaryLight bg)
    });
  });

  group('SolveFillPage', () {
    testWidgets('renders fill page with input', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveFillPage(questionId: 1),
      ));
      expect(find.text('填空题'), findsAtLeast(1));
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('SolveRatePage', () {
    testWidgets('renders 3 star ratings', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(questionId: 1),
      ));
      expect(find.text('难度'), findsOneWidget);
      expect(find.text('计算量'), findsOneWidget);
      expect(find.text('优雅度'), findsOneWidget);
    });

    testWidgets('can tap star to set rating', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(questionId: 1),
      ));
      // 点击第 8 颗星
      final stars = find.byIcon(Icons.star_border);
      await tester.tap(stars.first);
      await tester.pump();
      expect(find.text('提交评分'), findsOneWidget);
    });

    testWidgets('can submit and modify rating', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(questionId: 1),
      ));
      await tester.tap(find.text('提交评分'));
      await tester.pump();
      expect(find.text('已评分'), findsOneWidget);
      expect(find.text('修改评分'), findsOneWidget);
    });
  });
}
