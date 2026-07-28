/// 章鱼智学 — AssignmentRepository
/// data-db: assign.*
/// 对应页面：homework_list.html, homework_detail.html, index.html(待办数)

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

class AssignmentRepository {
  /// GET /api/assignments/pending/
  Future<List<AssignmentSummary>> getPending() async {
    throw UnimplementedError('AssignmentRepository.getPending');
  }

  /// GET /api/assignments/{id}/questions/
  Future<AssignmentDetail> getQuestions(int id) async {
    throw UnimplementedError('AssignmentRepository.getQuestions');
  }

  /// GET /api/assignments/pending/count/  → 待办作业数
  Future<int> pendingCount() async {
    throw UnimplementedError('AssignmentRepository.pendingCount');
  }
}
