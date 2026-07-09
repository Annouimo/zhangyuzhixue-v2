/// 章鱼智学 — PDF 试卷服务端输入数据类（SVG 使用）
///
/// 纯数据类，描述"要印什么"，不包含任何渲染/排版逻辑。
///
/// 设计稿约定：
/// - 使用 `final` + `const` 构造函数
/// - 不 import 任何项目内部模块
/// - 不存在依赖注入，所有数据通过构造函数传入
/// - LSP 报错（未解析的类型引用）是预期的
///
/// 数据来源：
/// - question 表（stem, question_type, images, default_score）
/// - choice_ext 表（options → PdfChoice[]）
/// - custom_paper 表（title）
/// - custom_paper_question 表（sort_order → 重编号）
///
/// 组装位置：Django 视图内（server/pdf/views.py）

/// 输出 PDF 时包含的版本信息
enum PdfVersion {
  /// 学生版：仅题目，无答案，留白供书写
  student,

  /// 教师版：含答案 + 分值标注（当前不做，预留）
  teacher,
}

/// 题型枚举
enum PdfQuestionType {
  choice,
  fill,
  solution,
}

/// 单个选项
class PdfChoice {
  final String label;
  final String content;

  const PdfChoice({
    required this.label,
    required this.content,
  });
}

/// 一道题
///
/// 每道题独立编号（在试卷内从 1 开始重新编号），
/// 含题干和配图路径，不含答案（学生版不输出答案）。
class PdfQuestion {
  /// 在本次试卷中的题号（从 1 连续编号）
  final int number;

  /// 题干（纯 Markdown + LaTeX，不含 `<img>` 标签）
  final String stem;

  /// 配图在 assets 中的路径列表
  ///
  /// 从 `question.images` JSON 字段 + assets 路径前缀拼装生成。
  /// HtmlBuilder 可据此做 `file://` 或 base64 嵌入。
  final List<String> imagePaths;

  /// 题型
  final PdfQuestionType type;

  /// 选择题的选项列表
  ///
  /// 仅 `type == choice` 时有值，fill / solution 为 null。
  final List<PdfChoice>? choices;

  const PdfQuestion({
    required this.number,
    required this.stem,
    this.imagePaths = const [],
    required this.type,
    this.choices,
  });
}

/// 一个大题区
///
/// 对应试卷中的"一、选择题""二、填空题""三、解答题"。
/// 每个 section 占据 1 页，从新页开始。
class PdfSection {
  /// 序号："一" / "二" / "三"
  final String label;

  /// 题型名："选择题" / "填空题" / "解答题"
  final String typeName;

  /// 分值信息："共40分"
  ///
  /// 由 PdfExamInputBuilder 从组内各题 default_score 累加生成。
  final String scoreInfo;

  /// 本大题内的题目列表
  ///
  /// 题号已在此范围内连续（不依赖原试卷题号）。
  final List<PdfQuestion> questions;

  const PdfSection({
    required this.label,
    required this.typeName,
    required this.scoreInfo,
    required this.questions,
  });
}

/// PDF 试卷生成器的完整输入
///
/// 描述一份试卷需要印的所有内容，不关心它在哪个平台/用什么工具渲染。
class PdfExamInput {
  /// 试卷标题（如"导数练习卷"）
  final String title;

  /// 是否显示姓名/班级/学号填空区（学生版 = true）
  final bool showStudentInfo;

  /// 输出版本（当前仅实现 student）
  final PdfVersion version;

  /// 大题区列表
  ///
  /// 约定顺序：[选择题, 填空题, 解答题]。
  /// PdfHtmlBuilder 按此顺序渲染，不重新排序。
  final List<PdfSection> sections;

  const PdfExamInput({
    required this.title,
    this.showStudentInfo = true,
    this.version = PdfVersion.student,
    required this.sections,
  });
}
