/// 章鱼智学 — LectureRepository
/// data-db: lecture.*
/// 对应页面：lecture_courses.html, lecture_chapters.html, lecture_content.html

class Course {
  final int id;
  final String name;
  final int chapterCount;

  const Course({required this.id, required this.name, required this.chapterCount});

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as int,
        name: json['name'] as String,
        chapterCount: json['chapter_count'] as int,
      );
}

class Chapter {
  final int id;
  final String title;
  final int pageCount;
  final String studyStatus;

  const Chapter({
    required this.id,
    required this.title,
    required this.pageCount,
    required this.studyStatus,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as int,
        title: json['title'] as String,
        pageCount: json['page_count'] as int,
        studyStatus: json['study_status'] as String,
      );
}

class ChapterList {
  final String courseName;
  final List<Chapter> items;

  const ChapterList({required this.courseName, required this.items});

  factory ChapterList.fromJson(Map<String, dynamic> json) => ChapterList(
        courseName: json['course_name'] as String,
        items: (json['items'] as List)
            .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LectureContent {
  final String title;
  final String body;
  final List<String> formulas;
  final int currentPage;
  final int totalPages;

  const LectureContent({
    required this.title,
    required this.body,
    required this.formulas,
    required this.currentPage,
    required this.totalPages,
  });

  factory LectureContent.fromJson(Map<String, dynamic> json) => LectureContent(
        title: json['title'] as String,
        body: json['body'] as String,
        formulas: (json['formulas'] as List).cast<String>(),
        currentPage: json['current_page'] as int,
        totalPages: json['total_pages'] as int,
      );

  String get pageInfo => '第 $currentPage / $totalPages 页';

  /// 分页列表（用于 data-db-loop），每页一个 id
  List<int> get pagination =>
      List.generate(totalPages, (i) => i + 1);
}

class LectureRepository {
  /// GET /api/lectures/courses/
  static Future<List<Course>> getCourses() async {
    throw UnimplementedError('LectureRepository.getCourses');
  }

  /// GET /api/lectures/courses/{courseId}/chapters/
  static Future<ChapterList> getChapters(int courseId) async {
    throw UnimplementedError('LectureRepository.getChapters');
  }

  /// GET /api/lectures/chapters/{chapterId}/content/
  static Future<LectureContent> getContent(int chapterId) async {
    throw UnimplementedError('LectureRepository.getContent');
  }
}
