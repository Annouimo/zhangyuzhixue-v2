import '../data/daos/lecture_dao.dart';

/// 一讲的讲义内容（镜像服务端 Document）
class LectureContent {
  final int chapterId;
  final String title;
  final String mdContent;

  const LectureContent({
    required this.chapterId,
    required this.title,
    required this.mdContent,
  });
}

/// 解析后的单页
class LecturePage {
  final List<String> blocks;
  final List<KnownCardRef> cardRefs;
  const LecturePage({required this.blocks, this.cardRefs = const []});
}

/// 知识卡片引用（从 markdown 注释标记中提取）
class KnownCardRef {
  final String title;
  final String content;
  const KnownCardRef({required this.title, required this.content});
}

/// 解析后的完整讲义
class LectureContentParsed {
  final List<LecturePage> pages;
  int get totalPages => pages.length;
  const LectureContentParsed({required this.pages});
}

/// 课程
class Course {
  final int id;
  final String name;
  final String description;
  final int chapterCount;
  const Course({
    required this.id,
    required this.name,
    this.description = '',
    required this.chapterCount,
  });
}

/// 讲
class Chapter {
  final int id;
  final String title;
  final int pageCount;
  const Chapter({
    required this.id,
    required this.title,
    required this.pageCount,
  });
}

/// 章节目录
class ChapterList {
  final String courseName;
  final List<Chapter> items;
  const ChapterList({required this.courseName, required this.items});
}

/// 讲义 Repository — 从 lectures 库读取，渲染时解析分隔符
class LectureRepository {
  final LectureDao _dao;

  /// 内存缓存：chapterId → LectureContentParsed，避免重复解析
  final Map<int, LectureContentParsed> _parseCache = {};

  LectureRepository(this._dao);

  Future<List<Course>> getCourses() async {
    final rows = await _dao.getAllCourses();
    final result = <Course>[];
    for (final r in rows) {
      final chCount = await _dao.chapterCount(r.id);
      result.add(
        Course(
          id: r.id,
          name: r.name,
          description: r.description ?? '',
          chapterCount: chCount,
        ),
      );
    }
    return result;
  }

  Future<ChapterList> getChapters(int courseId) async {
    final course = await _dao.getCourseById(courseId);
    final chapters = await _dao.getChapters(courseId);
    return ChapterList(
      courseName: course?.name ?? '',
      items: chapters
          .map((c) => Chapter(id: c.id, title: c.title, pageCount: 0))
          .toList(),
    );
  }

  Future<LectureContent> getContent(int chapterId) async {
    final row = await _dao.getContent(chapterId);
    if (row == null) throw Exception('Lecture content not found: $chapterId');
    return LectureContent(
      chapterId: chapterId,
      title: row.title,
      mdContent: row.mdContent,
    );
  }

  /// 解析 mdContent（带内存缓存），渲染层直接使用
  LectureContentParsed parseContent(LectureContent content) {
    final cached = _parseCache[content.chapterId];
    if (cached != null) return cached;
    final parsed = _parseMdContent(content.mdContent);
    _parseCache[content.chapterId] = parsed;
    return parsed;
  }

  void clearCache() => _parseCache.clear();
}

// ── 私有函数：分隔符解析 ──

LectureContentParsed _parseMdContent(String mdContent) {
  final knowcardPattern = RegExp(
    r'<!--\s*knowcard:\s*([\s\S]*?)\s*\|\s*([\s\S]*?)\s*-->',
  );

  final pages = mdContent
      .split('<!-- pagebreak -->')
      .where((p) => p.trim().isNotEmpty)
      .map((pageMd) {
        final blocks = pageMd
            .split('<!-- reveal -->')
            .map((b) => b.trim())
            .where((b) => b.isNotEmpty)
            .toList();

        // 从所有块中提取知识卡片引用
        final cardRefs = <KnownCardRef>[];
        for (int i = 0; i < blocks.length; i++) {
          final matches = knowcardPattern.allMatches(blocks[i]);
          if (matches.isNotEmpty) {
            for (final m in matches) {
              cardRefs.add(
                KnownCardRef(
                  title: m.group(1)!.trim(),
                  content: m.group(2)!.trim(),
                ),
              );
            }
            // 从块内容中移除标记
            blocks[i] = blocks[i].replaceAll(knowcardPattern, '').trim();
          }
        }
        // 过滤掉被清空的块
        blocks.removeWhere((b) => b.isEmpty);

        return LecturePage(blocks: blocks, cardRefs: cardRefs);
      })
      .toList();
  return LectureContentParsed(pages: pages);
}
