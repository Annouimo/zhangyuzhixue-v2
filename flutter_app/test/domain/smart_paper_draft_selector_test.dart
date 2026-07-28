import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/domain/smart_paper_draft_selector.dart';
import 'package:flutter_test/flutter_test.dart';

SearchQuestion question(int id, String type, double difficulty) =>
    SearchQuestion(
      id: id,
      title: '题目$id',
      questionType: type,
      meta: '',
      difficulty: difficulty,
      calculation: 0,
    );

void main() {
  const selector = SmartPaperDraftSelector();

  test('keeps locked questions and fills a balanced concrete draft', () {
    final locked = [question(99, 'solution', 5)];
    final candidates = [
      question(1, 'choice', 1),
      question(2, 'choice', 5),
      question(3, 'choice', 9),
      question(4, 'fill', 4),
      question(5, 'fill', 6),
      question(6, 'solution', 5),
    ];

    final result = selector.select(
      locked: locked,
      candidates: candidates,
      requestedCount: 5,
    );

    expect(result, hasLength(5));
    expect(result.first.id, 99);
    expect(result.map((item) => item.id).toSet(), hasLength(5));
    expect(
      result.map((item) => item.questionType),
      containsAll(['choice', 'fill', 'solution']),
    );
    expect(result.map((item) => item.id), contains(2));
  });
}
