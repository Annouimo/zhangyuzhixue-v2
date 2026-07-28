import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/question_bank/question_detail_presentation.dart';

void main() {
  test('single-item solution hierarchy omits redundant headings', () {
    expect(subQuestionHeading(count: 1, index: 0), isNull);
    expect(solutionMethodHeading(count: 1, index: 0), isNull);
    expect(solutionStepHeading(count: 1, index: 0, title: ''), isNull);
    expect(solutionStepHeading(count: 1, index: 0, title: '关键转换'), '关键转换');
  });

  test('multi-item solution hierarchy uses one-based presentation indexes', () {
    expect(subQuestionHeading(count: 2, index: 0), '第 1 小题');
    expect(solutionMethodHeading(count: 2, index: 0), '解法 1');
    expect(solutionMethodHeading(count: 2, index: 1, name: '数形结合'), '数形结合');
    expect(solutionStepHeading(count: 2, index: 0, title: ''), '第 1 步');
    expect(solutionStepHeading(count: 2, index: 1, title: '化简'), '第 2 步 · 化简');
  });
}
