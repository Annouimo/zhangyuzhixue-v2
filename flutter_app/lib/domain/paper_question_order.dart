const paperQuestionTypeOrder = <String>['choice', 'fill', 'solution'];

List<T> canonicalizePaperQuestions<T>(
  Iterable<T> questions,
  String Function(T question) typeOf,
) {
  final indexed = questions.indexed.toList(growable: false);
  indexed.sort((left, right) {
    final leftRank = paperQuestionTypeOrder.indexOf(typeOf(left.$2));
    final rightRank = paperQuestionTypeOrder.indexOf(typeOf(right.$2));
    final normalizedLeft = leftRank < 0
        ? paperQuestionTypeOrder.length
        : leftRank;
    final normalizedRight = rightRank < 0
        ? paperQuestionTypeOrder.length
        : rightRank;
    final typeComparison = normalizedLeft.compareTo(normalizedRight);
    return typeComparison != 0 ? typeComparison : left.$1.compareTo(right.$1);
  });
  return indexed.map((entry) => entry.$2).toList(growable: false);
}
