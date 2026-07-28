String? subQuestionHeading({required int count, required int index}) {
  if (count <= 1) return null;
  return '第 ${index + 1} 小题';
}

String? solutionMethodHeading({
  required int count,
  required int index,
  String? name,
}) {
  if (count <= 1) return null;
  final trimmedName = name?.trim();
  return trimmedName?.isNotEmpty == true ? trimmedName : '解法 ${index + 1}';
}

String? solutionStepHeading({
  required int count,
  required int index,
  required String title,
}) {
  if (count <= 1) return title.isEmpty ? null : title;
  return '第 ${index + 1} 步${title.isEmpty ? '' : ' · $title'}';
}
