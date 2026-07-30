import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/pdf_guide_dialog.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:shared/constants/app_version.dart';
import '../../data/api/api_client.dart';
import '../../data/database/database_provider.dart';
import '../../domain/paper_content.dart';

/// PDF 下载引导工具
class PdfHelper {
  static CancelToken? _cancelToken;

  /// 请求 PDF 浏览 URL
  ///
  /// 返回完整 URL（含域名），可直接传给 url_launcher。
  static Future<String> requestPdfUrl({
    required int sourceId,
    required String sourceType,
  }) async {
    // 如果是组卷，解析本地 ID → 服务端 ID
    if (sourceType == 'paper') {
      final db = DatabaseProvider().appDb;
      final paper = await (db.select(
        db.customPapers,
      )..where((t) => t.id.equals(sourceId))).getSingleOrNull();
      if (paper?.serverId != null) {
        sourceId = paper!.serverId!;
      }
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final res = await ApiClient().dio.post(
      '/interactions/pdf/request-token/',
      data: {'source_id': sourceId, 'source_type': sourceType},
      options: Options(
        sendTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 15),
      ),
      cancelToken: _cancelToken,
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final url = data['url'] as String;
    return '$appServerOrigin$url';
  }

  static Future<String> requestPdfUrlForPaper(PaperRef source) async {
    if (source is SavedPaperRef) {
      return requestPdfUrl(sourceId: source.paperId, sourceType: 'paper');
    }
    final virtual = source as VirtualPaperRef;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final res = await ApiClient().dio.post(
      '/interactions/pdf/request-token/',
      data: {
        'source_type': 'virtual_paper',
        'source': {
          'year': virtual.year,
          'exam_type': virtual.examType,
          'region': virtual.region,
        },
      },
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
      cancelToken: _cancelToken,
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return '$appServerOrigin${data['url'] as String}';
  }

  /// 取消未完成的 HTTP 请求。
  static void cancelRenew() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  /// 完整 PDF 下载/打印流程
  ///
  /// [sourceType] 当前固定为 'paper'
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
    try {
      final url = await requestPdfUrl(
        sourceId: sourceId,
        sourceType: sourceType,
      );
      var action = PdfGuideAction.open;
      if (context != null && context.mounted) {
        final selected = await showPdfGuideDialog(context);
        if (selected == null) return;
        action = selected;
      }

      if (action == PdfGuideAction.copy) {
        await Clipboard.setData(ClipboardData(text: url));
        if (context != null && context.mounted) {
          AppToast.success(context, '链接已复制，可通过微信、QQ等方式发送到电脑');
        }
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PdfHelper] 打开 PDF 失败: $e');
      if (context != null && context.mounted) {
        AppToast.error(context, '无法打开 PDF，请检查网络后重试');
      }
    }
  }

  static Future<void> downloadPaperPdf({
    required PaperRef source,
    BuildContext? context,
  }) async {
    try {
      final url = await requestPdfUrlForPaper(source);
      var action = PdfGuideAction.open;
      if (context != null && context.mounted) {
        final selected = await showPdfGuideDialog(context);
        if (selected == null) return;
        action = selected;
      }
      if (action == PdfGuideAction.copy) {
        await Clipboard.setData(ClipboardData(text: url));
        if (context != null && context.mounted) {
          AppToast.success(context, '链接已复制，可通过微信、QQ等方式发送到电脑');
        }
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PdfHelper] 打开 PDF 失败: $e');
      if (context != null && context.mounted) {
        AppToast.error(context, '无法打开 PDF，请检查网络后重试');
      }
    }
  }
}
