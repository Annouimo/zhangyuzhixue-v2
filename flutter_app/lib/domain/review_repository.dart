import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';

enum ConceptProgressStatus { insufficient, forming, needsReview, stable }

class ConceptProgress {
  const ConceptProgress({
    required this.name,
    required this.attemptCount,
    required this.accuracy,
    required this.status,
  });

  final String name;
  final int attemptCount;
  final double accuracy;
  final ConceptProgressStatus status;
}

class ReviewRepository {
  const ReviewRepository(this._questionDao, this._progressDao);

  final QuestionDao _questionDao;
  final ProgressDao _progressDao;

  Future<List<ConceptProgress>> getConceptProgress() async {
    final attempts = await _progressDao.getAllAttempts();
    final links = await _questionDao.getAllQuestionTagLinks();
    final tags = await _questionDao.getAllConceptTags();
    final questionTags = <int, Set<int>>{};
    for (final link in links) {
      questionTags
          .putIfAbsent(link.questionId, () => <int>{})
          .add(link.conceptTagId);
    }

    final totals = <int, int>{};
    final correct = <int, int>{};
    for (final attempt in attempts.where((item) => item.isCorrect != null)) {
      for (final tagId in questionTags[attempt.questionId] ?? const <int>{}) {
        totals[tagId] = (totals[tagId] ?? 0) + 1;
        if (attempt.isCorrect == 1) correct[tagId] = (correct[tagId] ?? 0) + 1;
      }
    }

    final result = tags
        .map((tag) {
          final total = totals[tag.id] ?? 0;
          final accuracy = total == 0 ? 0.0 : (correct[tag.id] ?? 0) / total;
          final status = total < 2
              ? ConceptProgressStatus.insufficient
              : accuracy < 0.5
              ? ConceptProgressStatus.needsReview
              : total < 4 || accuracy < 0.8
              ? ConceptProgressStatus.forming
              : ConceptProgressStatus.stable;
          return ConceptProgress(
            name: tag.name,
            attemptCount: total,
            accuracy: accuracy,
            status: status,
          );
        })
        .where((item) => item.attemptCount > 0)
        .toList();

    result.sort((a, b) {
      int rank(ConceptProgressStatus status) => switch (status) {
        ConceptProgressStatus.needsReview => 0,
        ConceptProgressStatus.forming => 1,
        ConceptProgressStatus.stable => 2,
        ConceptProgressStatus.insufficient => 3,
      };
      final statusCompare = rank(a.status).compareTo(rank(b.status));
      if (statusCompare != 0) return statusCompare;
      return b.attemptCount.compareTo(a.attemptCount);
    });
    return result;
  }
}
