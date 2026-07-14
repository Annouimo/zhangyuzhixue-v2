import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/pdf_guide_dialog.dart';
import '../../constants/app_version.dart';
import '../../data/api/api_client.dart';

const _guideDismissedKey = 'app_pdf_guide_dismissed';

/// PDF 下载引导工具
///
/// 调用链：
///   downloadPdf()
///     1. 检查 SharedPreferences pdf_guide_dismissed
///        - false → 弹窗引导
///        - true → 跳过
///     2. requestPdfUrl() → 获取带签名 URL + 自动续期 Timer
///     3. launchUrl() → 打开系统浏览器
class PdfHelper {
  // ── 缓存与定时器状态 ──
  static String? _cachedUrl;
  static int? _cachedSourceId;
  static String? _cachedSourceType;
  static Timer? _renewTimer;

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

  /// 请求 PDF 浏览 URL
  ///
  /// 自动启动 sig 自动续期 Timer（到期前 ~60 秒重请求）
  /// 返回完整 URL（含域名），可直接传给 url_launcher。
  static Future<String> requestPdfUrl({
    required int sourceId,
    required String sourceType,
  }) async {
    final res = await ApiClient().dio.post(
      '/interactions/pdf/request-token/',
      data: {
        'source_id': sourceId,
        'source_type': sourceType,
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final url = data['url'] as String;
    final expireIn = data['expire_in'] as int;

    // 缓存状态（用于续期）
    _cachedUrl = '$appServerOrigin$url';
    _cachedSourceId = sourceId;
    _cachedSourceType = sourceType;

    // 启动自动续期
    _startRenewTimer(expireIn);

    return _cachedUrl!;
  }

  /// 启动 sig 自动续期定时器
  ///
  /// 在过期前约 60 秒重新请求新签名，避免用户操作过程中 URL 失效。
  static void _startRenewTimer(int expireIn) {
    _renewTimer?.cancel();
    // 至少保留 10 秒缓冲，防止极端情况
    final delay = Duration(
      seconds: (expireIn - 60).clamp(10, expireIn),
    );
    _renewTimer = Timer(delay, () async {
      try {
        if (_cachedSourceId != null && _cachedSourceType != null) {
          await requestPdfUrl(
            sourceId: _cachedSourceId!,
            sourceType: _cachedSourceType!,
          );
        }
      } catch (_) {
        // 续期失败不影响已有 URL（旧 URL 还有约 60 秒有效）
      }
    });
  }

  /// 取消自动续期
  static void cancelRenew() {
    _renewTimer?.cancel();
    _renewTimer = null;
    _cachedUrl = null;
    _cachedSourceId = null;
    _cachedSourceType = null;
  }

  /// 完整 PDF 下载/打印流程
  ///
  /// [sourceType] 'paper'（默认）| 'assignment'
  /// [context] 可选，提供时若引导未关闭则弹出引导弹窗
  ///
  /// 使用方示例：
  ///   PdfHelper.downloadPdf(sourceId: paperId, sourceType: 'paper');
  ///   PdfHelper.downloadPdf(sourceId: paperId, sourceType: 'paper', context: context);
  static Future<void> downloadPdf({
    required int sourceId,
    required String sourceType,
    BuildContext? context,
  }) async {
    // 如果提供了 context 且引导未关闭 → 弹窗引导
    if (context != null && context.mounted) {
      final dismissed = await isGuideDismissed();
      if (!dismissed) {
        if (!context.mounted) return;
        final shouldOpen = await showPdfGuideDialog(context);
        if (shouldOpen != true) return;
      }
    }

    // 获取 URL 并打开浏览器
    try {
      final url = await requestPdfUrl(
        sourceId: sourceId,
        sourceType: sourceType,
      );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PdfHelper] 打开 PDF 失败: $e');
    }
  }
}
