import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

const _guideDismissedKey = 'app_pdf_guide_dismissed';

/// PDF 下载引导工具
///
/// 调用链：
///   downloadPdf()
///     1. 检查 SharedPreferences pdf_guide_dismissed
///        - false → 弹窗引导（由调用方处理 UI）
///        - true → 跳过
///     2. requestPdfUrl() → 获取带签名 URL
///     3. launchUrl() → 打开系统浏览器
class PdfHelper {
  /// 是否已关闭引导
  static Future<bool> isGuideDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guideDismissedKey) ?? false;
  }

  /// 标记引导已关闭
  static Future<void> dismissGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guideDismissedKey, true);
  }

  /// 请求 PDF 浏览 URL（通过 POST /api/v1/pdf/request-token/）
  ///
  /// [sourceType] 'paper' | 'assignment'
  /// 返回完整 URL（含域名如 zhangyuzhixue.top），可直接传给 url_launcher。
  static Future<String> requestPdfUrl({
    required int sourceId,
    required String sourceType,
  }) async {
    final res = await ApiClient().dio.post('/pdf/request-token/', data: {
      'source_id': sourceId,
      'source_type': sourceType,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final url = data['url'] as String;
    // 构造完整 URL（API 返回的是相对路径）
    return 'https://zhangyuzhixue.top$url';
  }

  /// 完整 PDF 下载/打印流程
  ///
  /// [sourceType] 'paper'（默认）| 'assignment'
  ///
  /// 使用方示例：
  ///   PdfHelper.downloadPdf(sourceId: paperId, sourceType: 'paper');
  static Future<void> downloadPdf({
    required int sourceId,
    required String sourceType,
  }) async {
    final url = await requestPdfUrl(sourceId: sourceId, sourceType: sourceType);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
