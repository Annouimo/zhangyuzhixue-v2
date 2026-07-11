/// 章鱼智学 — LectureRepository
/// data-db: lecture.*
/// 对应页面：lecture_courses.html, lecture_chapters.html, lecture_content.html
///
/// ====== 设计要点（方案 B）======
///
/// 服务端存储：Document.md_content 为完整的 markdown 文本，含预定分隔符：
///   <!-- pagebreak -->  ← 分页标记
///   <!-- reveal -->      ← 同一页内展开块分割标记
///
/// 客户端存储：lecture_content 表镜像服务端，md_content 字段与原字段一致。
/// 构建脚本和 API 均不做解析，直接存储/返回原始 markdown。
///
/// 渲染时解析：通过 _parseMdContent() 将 md_content 拆分为 pages[].blocks[]，
/// 结果用内存 Map 缓存（Map<int, LectureContentParsed>），避免重复解析。
/// 解析结果不持久化到本地数据库。

/// 一讲（Chapter）的讲义内容（镜像服务端 Document 的结构）
class LectureContent {
  final int chapterId;
  final String title;
  final String mdContent; // 含分隔符的原始 markdown

  const LectureContent({
    required this.chapterId,
    required this.title,
    required this.mdContent,
  });

  factory LectureContent.fromJson(Map<String, dynamic> json) => LectureContent(
        chapterId: json['chapter_id'] as int,
        title: json['title'] as String,
        mdContent: json['md_content'] as String,
      );
}

/// 解析后的单页内容
class LecturePage {
  /// blocks[0] 默认可见，blocks[1..] 为 REVEAL 块（逐步点击展开）
  final List<String> blocks;

  const LecturePage({required this.blocks});
}

/// 解析后的完整讲义（渲染层直接使用）
class LectureContentParsed {
  final List<LecturePage> pages;

  int get totalPages => pages.length;

  const LectureContentParsed({required this.pages});
}

// ---- 私有函数：分隔符解析，仅本文件内部调用 ----
LectureContentParsed _parseMdContent(String mdContent) {
  final pages = mdContent
      .split("<!-- pagebreak -->")
      .where((p) => p.trim().isNotEmpty)
      .map((pageMd) {
    final blocks = pageMd
        .split("<!-- reveal -->")
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    return LecturePage(blocks: blocks);
  }).toList();
  return LectureContentParsed(pages: pages);
}

/// 课程（镜像服务端 Course 的结构）
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

/// 讲（镜像服务端 Document 的元数据，不含内容）
class Chapter {
  final int id;
  final String title;
  final int pageCount; // 预计算页数（asset 构建时从 md 统计，API 端同理）

  const Chapter({
    required this.id,
    required this.title,
    required this.pageCount,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as int,
        title: json['title'] as String,
        pageCount: json['page_count'] as int,
      );
}

/// 章节列表
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

/// 讲义 Repository
///
/// 数据来源：本地 drift 表 lecture_content（镜像服务端 Document）。
/// 本地读取后通过 _parseMdContent() 完成结构化，结果用内存缓存。
class LectureRepository {
  /// GET /api/lectures/courses/ 或 本地 drift course 表
  Future<List<Course>> getCourses() async {
    throw UnimplementedError('LectureRepository.getCourses');
  }

  /// GET /api/lectures/courses/{courseId}/chapters/ 或 本地 drift chapter 表
  Future<ChapterList> getChapters(int courseId) async {
    throw UnimplementedError('LectureRepository.getChapters');
  }

  /// 从本地 drift lecture_content 表读取该讲原始 markdown
  /// 渲染层收到 LectureContent 后调用 _parseMdContent() 解析
  Future<LectureContent> getContent(int chapterId) async {
    throw UnimplementedError('LectureRepository.getContent');
  }
}
