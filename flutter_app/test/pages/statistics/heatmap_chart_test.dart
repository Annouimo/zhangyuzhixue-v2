import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/statistics/widgets/heatmap_chart.dart';
import 'package:flutter_app/domain/statistics_repository.dart';

void main() {
  group('HeatmapChart', () {
    testWidgets('renders with records', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: HeatmapChart(rangeDays: 7, records: [
          const DailyRecord(date: '2025-01-01', count: 3, level: 2),
        ]),
      )));
      expect(find.text('做题热力图'), findsOneWidget);
    });
  });
}
