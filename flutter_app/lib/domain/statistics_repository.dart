import '../data/daos/statistics_dao.dart';
import '../data/daos/question_dao.dart';

/// 统计概览
class StatsOverview {
  final int totalQuestions;
  final double accuracyPercent;
  final int streakDays;
  final int activeDays;

  const StatsOverview({
    required this.totalQuestions,
    required this.accuracyPercent,
    required this.streakDays,
    required this.activeDays,
  });
}

/// 每日记录
class DailyRecord {
  final String date;
  final int count;
  final int correct;
  final int level;
  const DailyRecord({required this.date, required this.count, required this.correct, required this.level});
}

/// 趋势点
class TrendPoint {
  final String label;
  final double value;
  const TrendPoint({required this.label, required this.value});
}

/// 题型分布
class Distribution {
  final int total;
  final int choiceCount;
  final double choicePercent;
  final int fillCount;
  final double fillPercent;
  final int solutionCount;
  final double solutionPercent;

  const Distribution({
    required this.total,
    required this.choiceCount,
    required this.choicePercent,
    required this.fillCount,
    required this.fillPercent,
    required this.solutionCount,
    required this.solutionPercent,
  });
}

/// 统计 Repository — 委托 StatisticsDao + QuestionDao
class StatisticsRepository {
  final StatisticsDao _dao;
  final QuestionDao? _questionDao;

  const StatisticsRepository(this._dao, {this._questionDao});

  Future<StatsOverview> getOverview() async {
    final raw = await _dao.getOverviewRaw();
    return StatsOverview(
      totalQuestions: raw.totalQuestions,
      accuracyPercent: raw.accuracy * 100,
      streakDays: raw.streakDays,
      activeDays: raw.activeDays,
    );
  }

  /// 从 DailyRecords 派生正确率趋势（避免重复查询）
  static List<TrendPoint> deriveAccuracyTrend(List<DailyRecord> records) {
    if (records.isEmpty) return [];
    final points = <TrendPoint>[];
    for (final r in records) {
      if (r.count == 0) continue;
      points.add(TrendPoint(label: r.date, value: r.correct / r.count * 100));
    }
    if (points.length > 30) {
      final sampled = <TrendPoint>[];
      final step = (points.length / 30).ceil();
      for (var i = 0; i < points.length; i += step) {
        final end = (i + step > points.length) ? points.length : i + step;
        final slice = points.sublist(i, end);
        final avgValue = slice.fold<double>(0, (s, p) => s + p.value) / slice.length;
        sampled.add(TrendPoint(
          label: slice[slice.length ~/ 2].label,
          value: avgValue,
        ));
      }
      return sampled;
    }
    return points;
  }

  Future<List<DailyRecord>> getDailyRecords(int rangeDays) async {
    final raw = await _dao.getDailyRecords(rangeDays);
    return _StatisticsAggregator.aggregateDailyRecords(raw);
  }

  Future<List<TrendPoint>> getPointsTrend(int rangeDays) async {
    final raw = await _dao.getPointsByDay(rangeDays);
    if (raw.isEmpty) return [];
    var cum = 0.0;
    final points = <TrendPoint>[];
    for (final r in raw) {
      cum += r.amount;
      points.add(TrendPoint(label: r.date, value: cum));
    }
    if (points.length > 30) {
      final sampled = <TrendPoint>[];
      final step = (points.length / 30).ceil();
      for (var i = 0; i < points.length; i += step) {
        sampled.add(points[i]);
      }
      return sampled;
    }
    return points;
  }

  Future<Distribution> getDistribution({int rangeDays = 0}) async {
    final qids = await _dao.getAttemptedQuestionIds(rangeDays: rangeDays);
    var choice = 0, fill = 0, solution = 0;
    if (_questionDao != null && qids.isNotEmpty) {
      final questions = await _questionDao.getByIds(qids);
      for (final q in questions) {
        if (q.questionType == 'choice') {
          choice++;
        } else if (q.questionType == 'fill') {
          fill++;
        } else if (q.questionType == 'solution') {
          solution++;
        }
      }
    }
    final total = choice + fill + solution;
    return Distribution(
      total: total,
      choiceCount: choice,
      choicePercent: total > 0 ? choice / total * 100 : 0,
      fillCount: fill,
      fillPercent: total > 0 ? fill / total * 100 : 0,
      solutionCount: solution,
      solutionPercent: total > 0 ? solution / total * 100 : 0,
    );
  }
}

// ── 统计聚合引擎 ──
class _StatisticsAggregator {
  static List<DailyRecord> aggregateDailyRecords(
    List<({String date, int count, int correct})> raw,
  ) {
    if (raw.isEmpty) return [];
    final grouped = <String, ({int count, int correct})>{};
    for (final r in raw) {
      final cur = grouped[r.date] ?? (count: 0, correct: 0);
      grouped[r.date] = (count: cur.count + r.count, correct: cur.correct + r.correct);
    }
    final maxCount = grouped.values.fold(0, (int m, v) => v.count > m ? v.count : m);
    final list = grouped.entries.map((e) => DailyRecord(
      date: e.key,
      count: e.value.count,
      correct: e.value.correct,
      level: _relativeLevel(e.value.count, maxCount),
    )).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// 按当前最大值做三等分相对分档（匹配 HTML 的 levelOf(v, max)）
  static int _relativeLevel(int count, int max) {
    if (max == 0 || count == 0) return 0;
    final r = count / max;
    if (r <= 0.33) return 1;
    if (r <= 0.66) return 2;
    return 3;
  }
}
