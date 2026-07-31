import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import 'exam_repository.dart';

enum QuestionReviewScope { currentWrong, corrected }

class QuestionReviewSummary {
  final int currentWrongCount;
  final int correctedCount;

  const QuestionReviewSummary({
    required this.currentWrongCount,
    required this.correctedCount,
  });
}

abstract interface class QuestionReviewRepository {
  Future<QuestionReviewSummary> getSummary();

  Future<List<SearchQuestion>> getQuestions(QuestionReviewScope scope);
}

class LocalQuestionReviewRepository implements QuestionReviewRepository {
  final ProgressDao _progressDao;
  final QuestionDao _questionDao;

  const LocalQuestionReviewRepository(this._progressDao, this._questionDao);

  @override
  Future<QuestionReviewSummary> getSummary() async {
    final ids = await _progressDao.getQuestionReviewIds();
    return QuestionReviewSummary(
      currentWrongCount: ids.currentWrong.length,
      correctedCount: ids.corrected.length,
    );
  }

  @override
  Future<List<SearchQuestion>> getQuestions(QuestionReviewScope scope) async {
    final reviewIds = await _progressDao.getQuestionReviewIds();
    final ids = scope == QuestionReviewScope.currentWrong
        ? reviewIds.currentWrong
        : reviewIds.corrected;
    final rows = await _questionDao.getByIds(ids.toList());
    rows.sort((left, right) => left.id.compareTo(right.id));
    return rows
        .map(
          (row) => SearchQuestion(
            id: row.id,
            title: row.stem,
            questionType: row.questionType,
            meta: '${row.year} ${row.examType} ${row.region}',
            difficulty: row.difficulty ?? 0,
            calculation: row.calculation ?? 0,
          ),
        )
        .toList(growable: false);
  }
}
