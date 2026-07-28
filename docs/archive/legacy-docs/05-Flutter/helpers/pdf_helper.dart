/// 章鱼智学 — PdfHelper
///
/// PDF 下载流程的共享工具。供 ExamRepository、AssignmentRepository
/// 等多个 Repository 复用。
///
/// 调用链：
///   downloadPdf()
///     1. 检查 SharedPreferences pdf_guide_dismissed
///        - false → 弹出 PdfGuideDialog
///          - 用户取消 → 结束
///          - 用户确认 → 继续
///        - true → 跳过弹窗
///     2. requestPdfUrl(sourceId, sourceType) → String url
///     3. launchUrl(Uri.parse('https://$domain$url'),
///          mode: LaunchMode.externalApplication)
///
/// 流程说明：
/// - 不额外消耗积分（组卷时已扣）
/// - sig 有效期 5 分钟，expire_in < 60s 时自动续期
/// - 公开试卷可被任意登录学生下载

/// PDF 下载引导工具
class PdfHelper {
  /// 请求 PDF 浏览 URL（通过 /api/v1/pdf/request-token）
  ///
  /// [sourceType] 取值：
  ///   - 'paper' — 组卷，sourceId = custom_paper.id
  ///   - 'assignment' — 作业，sourceId = assignment.id
  ///
  /// 返回完整 URL（含域名），可直接传给 url_launcher。
  static Future<String> requestPdfUrl({
    required int sourceId,
    required String sourceType,
  }) async {
    throw UnimplementedError('PdfHelper.requestPdfUrl');
  }

  /// 完整 PDF 下载/打印流程
  ///
  /// 包含：引导弹窗 → 请求 URL → 打开系统浏览器。
  /// 用户在浏览器中按 Ctrl+P（桌面）或菜单→打印（手机）完成输出。
  ///
  /// [sourceType] 取值：
  ///   - 'paper'（默认）— 组卷，sourceId = custom_paper.id
  ///   - 'assignment' — 作业，sourceId = assignment.id
  ///
  /// 使用方示例：
  /// ```dart
  /// // ExamRepository
  /// static Future<void> downloadPdf(int paperId) {
  ///   return PdfHelper.downloadPdf(
  ///     sourceId: paperId,
  ///     sourceType: 'paper',
  ///   );
  /// }
  ///
  /// // AssignmentRepository
  /// static Future<void> downloadPdf(int assignmentId) {
  ///   return PdfHelper.downloadPdf(
  ///     sourceId: assignmentId,
  ///     sourceType: 'assignment',
  ///   );
  /// }
  /// ```
  static Future<void> downloadPdf({
    required int sourceId,
    required String sourceType,
  }) async {
    throw UnimplementedError('PdfHelper.downloadPdf');
  }
}
