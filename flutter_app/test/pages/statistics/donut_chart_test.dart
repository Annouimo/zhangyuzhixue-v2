import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/statistics/widgets/donut_chart.dart';
import 'package:flutter_app/domain/statistics_repository.dart';

void main() {
  group('DonutChart', () {
    testWidgets('shows placeholder when empty', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DonutChart(data: const Distribution(total: 0, choiceCount: 0, choicePercent: 0, fillCount: 0, fillPercent: 0, solutionCount: 0, solutionPercent: 0)),
      )));
      expect(find.text('题型分布'), findsOneWidget);
      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('shows distribution with data', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: DonutChart(data: const Distribution(total: 10, choiceCount: 5, choicePercent: 50, fillCount: 3, fillPercent: 30, solutionCount: 2, solutionPercent: 20)),
      )));
      expect(find.text('5 题'), findsOneWidget);
      expect(find.text('3 题'), findsOneWidget);
      expect(find.text('2 题'), findsOneWidget);
    });
  });
}
