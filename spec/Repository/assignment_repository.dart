/// 章鱼智学 — AssignmentRepository
/// 对应页面：homework.html, homework_detail.html
/// data-db: assign.getPending.*, assign.getQuestions.*

class AssignmentSummary {
  final int id;
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int deadlineDays;
  final String status;

  const AssignmentSummary({
    required this.id,
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.status,
  });

  factory AssignmentSummary.fromJson(Map<String, dynamic> json) =>
      AssignmentSummary(
        id: json['id'] as int,
        title: json['title'] as String,
        courseName: json['course_name'] as String,
        doneCount: json['done_count'] as int,
        totalCount: json['total_count'] as int,
        deadlineDays: json['deadline_remaining'] as int,
        status: json['status'] as String,
      );
}

class AssignmentDetail {
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int deadlineDays;
  final List<QuestionSummary> questions;

  const AssignmentDetail({
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.questions,
  });

  factory AssignmentDetail.fromJson(Map<String, dynamic> json) =>
      AssignmentDetail(
        title: json['title'] as String,
        courseName: json['course_name'] as String,
        doneCount: json['done_count'] as int,
        totalCount: json['total_count'] as int,
        deadlineDays: json['deadline_remaining'] as int,
        questions: (json['questions'] as List)
            .map((e) => QuestionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class QuestionSummary {
  final int id;
  final String number;
  final String questionType;
  final String status;

  const QuestionSummary({
    required this.id,
    required this.number,
    required this.questionType,
    required this.status,
  });

  factory QuestionSummary.fromJson(Map<String, dynamic> json) =>
      QuestionSummary(
        id: json['id'] as int,
        number: json['number'] as String,
        questionType: json['question_type'] as String,
        status: json['status'] as String,
      );
}

class AssignmentRepository {
  /// GET /api/assignments/pending/
  static Future<List<AssignmentSummary>> getPendingAssignments() async {
    throw UnimplementedError('AssignmentRepository.getPendingAssignments');
  }

  /// GET /api/assignments/{id}/questions/
  static Future<AssignmentDetail> getAssignmentQuestions(int id) async {
    throw UnimplementedError('AssignmentRepository.getAssignmentQuestions');
  }
}
