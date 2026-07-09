/// 章鱼智学 — LectureParser
///
/// 讲义 Markdown 分隔符解析工具。
///
/// 服务端存储：Document.md_content 为完整的 markdown 文本，含预定分隔符：
///   <!-- pagebreak -->  ← 分页标记
///   <!-- reveal -->      ← 同一页内展开块分割标记
///
/// 解析策略：
/// - 客户端收到原始 md_content 后本地解析，结果用内存缓存
///   （Map<int, LectureContentParsed>），避免重复解析。
/// - 解析结果不持久化到本地数据库。
/// - 复习模式（review=true）忽略所有分隔符，全部内容作为单页渲染。
///
/// 使用方：LectureRepository（渲染层在收到 LectureContent 后调用本工具解析）

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

/// 讲义 Markdown 解析器
///
/// 输入：含 <!-- pagebreak --> 和 <!-- reveal --> 分隔符的原始 markdown
/// 输出：LectureContentParsed（pages[].blocks[] 结构）
///
/// 使用方示例：
/// ```dart
/// final content = await LectureRepository.getContent(chapterId);
/// final parsed = parseMdContent(content.mdContent, review: false);
/// // parsed.pages[0].blocks[0]  → 第 1 页默认可见块
/// // parsed.pages[0].blocks[1]  → 第 1 页第 1 个展开块
/// ```
LectureContentParsed parseMdContent(String mdContent, {bool review = false}) {
  if (review) {
    return LectureContentParsed(
      pages: [LecturePage(blocks: [mdContent])],
    );
  }
  final pages = mdContent
      .split('<!-- pagebreak -->')
      .where((p) => p.trim().isNotEmpty)
      .map((pageMd) {
    final blocks = pageMd
        .split('<!-- reveal -->')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    return LecturePage(blocks: blocks);
  }).toList();
  return LectureContentParsed(pages: pages);
}
