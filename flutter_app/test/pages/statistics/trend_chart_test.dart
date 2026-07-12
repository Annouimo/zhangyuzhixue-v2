import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/statistics/widgets/trend_chart.dart';
import 'package:flutter_app/domain/statistics_repository.dart';
import '../../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  group('TrendChart', () {
    testWidgets('shows placeholder when empty', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: TrendChart(title: '正确率趋势', points: []),
      )));
      expect(find.text('正确率趋势'), findsOneWidget);
      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('renders with points', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: TrendChart(title: '积分累计', points: [
          const TrendPoint(label: '周一', value: 10),
          const TrendPoint(label: '周二', value: 20),
        ]),
      )));
      expect(find.text('积分累计'), findsOneWidget);
      expect(find.byType(CustomPaint), findsAtLeast(1));
    });
  });
}
