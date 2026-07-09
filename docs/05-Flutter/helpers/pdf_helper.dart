/// 章鱼智学 — PdfHelper
/// 共享 PDF 下载逻辑，与 question_status_helper 同级
/// 供 ExamRepository、AssignmentRepository 等多个 Repository 复用
///
/// 调用链：
///   downloadPdf()
///     → _showPrintGuide() 检查 SharedPreferences pdf_guide_dismissed
///     → requestPdfUrl(sourceId, sourceType) → String url
///     → launchUrl(Uri.parse('https://$domain$url'), mode: LaunchMode.externalApplication)

class PdfHelper {
  /// 请求 PDF 浏览 URL（通过 /api/v1/pdf/request-token）
  static Future<String> requestPdfUrl({
    required int sourceId,
    required String sourceType,
  }) async {
    throw UnimplementedError('PdfHelper.requestPdfUrl');
  }

  /// 完整下载流程
  ///
  /// [sourceType] 取值：
  ///   - 'paper'（默认）— 组卷，sourceId = custom_paper.id
  ///   - 'assignment' — 作业，sourceId = assignment.id
  static Future<void> downloadPdf({
    required int sourceId,
    required String sourceType,
  }) async {
    throw UnimplementedError('PdfHelper.downloadPdf');
  }
}
