import 'exam_repository.dart';

sealed class PaperRef {
  const PaperRef();
}

class SavedPaperRef extends PaperRef {
  final int paperId;

  const SavedPaperRef(this.paperId);
}

class VirtualPaperRef extends PaperRef {
  final int year;
  final String examType;
  final String region;

  const VirtualPaperRef({
    required this.year,
    required this.examType,
    required this.region,
  });

  String get title => '$year$region$examType';
}

class PaperContent {
  final PaperRef ref;
  final String title;
  final String subtitle;
  final bool isPublic;
  final List<ExamQuestion> questions;

  const PaperContent({
    required this.ref,
    required this.title,
    required this.subtitle,
    required this.questions,
    this.isPublic = false,
  });
}
