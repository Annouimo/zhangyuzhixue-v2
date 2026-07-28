import 'exam_repository.dart';

class SmartPaperDraftSelector {
  const SmartPaperDraftSelector();

  List<SearchQuestion> select({
    required List<SearchQuestion> locked,
    required List<SearchQuestion> candidates,
    required int requestedCount,
  }) {
    final lockedIds = locked.map((question) => question.id).toSet();
    final availableByType = <String, List<SearchQuestion>>{
      'choice': [],
      'fill': [],
      'solution': [],
    };
    for (final question in candidates) {
      if (!lockedIds.contains(question.id)) {
        availableByType[question.questionType]?.add(question);
      }
    }

    final targetDifficulty = candidates.isEmpty
        ? 0.0
        : candidates.fold<double>(
                0,
                (sum, question) => sum + question.difficulty,
              ) /
              candidates.length;
    for (final pool in availableByType.values) {
      pool.sort(
        (left, right) => (left.difficulty - targetDifficulty).abs().compareTo(
          (right.difficulty - targetDifficulty).abs(),
        ),
      );
    }

    final additions = <String, int>{'choice': 0, 'fill': 0, 'solution': 0};
    var remaining = (requestedCount - locked.length).clamp(
      0,
      candidates.length,
    );
    while (remaining > 0) {
      String? bestType;
      double bestScore = -1;
      for (final entry in availableByType.entries) {
        final capacity = entry.value.length - additions[entry.key]!;
        if (capacity <= 0) continue;
        final score = entry.value.length / (additions[entry.key]! + 1);
        if (score > bestScore) {
          bestType = entry.key;
          bestScore = score;
        }
      }
      if (bestType == null) break;
      additions.update(bestType, (count) => count + 1);
      remaining--;
    }

    return [
      ...locked,
      for (final type in const ['choice', 'fill', 'solution'])
        ...availableByType[type]!.take(additions[type]!),
    ];
  }
}
