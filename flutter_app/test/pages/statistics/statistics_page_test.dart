import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/statistics_repository.dart';
import 'package:flutter_app/pages/statistics/statistics_page.dart';
import '../../test_setup.dart';

class _MockStatsRepo implements StatisticsRepository {
  @override Future<StatsOverview> getOverview() async => const StatsOverview(totalQuestions: 100, accuracyPercent: 75, streakDays: 5, activeDays: 5);
  @override Future<int> totalQuestions() async => 100;
  @override Future<double> accuracy() async => 0.75;
  @override Future<List<DailyRecord>> getDailyRecords(int rangeDays) async => [const DailyRecord(date: '2025-01-01', count: 3, correct: 2, level: 2)];
  @override Future<List<TrendPoint>> getAccuracyTrend(int rangeDays) async => [];
  @override Future<List<TrendPoint>> getPointsTrend(int rangeDays) async => [];
  @override Future<Distribution> getDistribution() async => const Distribution(total: 10, choiceCount: 5, choicePercent: 50, fillCount: 3, fillPercent: 30, solutionCount: 2, solutionPercent: 20);
}

void main() {
    setUp(() => setupTestHooks());
  group('StatisticsPage', () {
    testWidgets('shows loading then overview cards', (tester) async {
      await tester.pumpWidget(MaterialApp(home: StatisticsPage(statisticsRepository: _MockStatsRepo())));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('5 天'), findsOneWidget);
    });
  });
}
