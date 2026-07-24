import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/theme/app_theme.dart';
import '../data/helpers/pdf_helper.dart';

/// PDF 引导弹窗
///
/// 返回 true 表示用户点击了"打开浏览器"，false 表示取消。
/// 如果用户勾选了"不再提示"，弹窗内直接保存到 SharedPreferences。
Future<bool?> showPdfGuideDialog(BuildContext context) async {
  bool dontShowAgain = false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.description, size: 24, color: AppColors.primary),
            SizedBox(width: 8),
            Text('准备打印试卷',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('试卷已生成，请在浏览器中完成打印：',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text('电脑用户：',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('按 Ctrl+P 打开打印对话框\n选择「另存为 PDF」或直接打印'),
            ),
            const SizedBox(height: 12),
            const Text('手机用户：',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('点击浏览器菜单 (⋮) → 分享 → 打印 → 选择「保存为 PDF」'),
            ),
            const SizedBox(height: 12),
            const Text('纸张选择 A4，取消页眉页脚 ✓',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (v) => setState(() => dontShowAgain = v ?? false),
                ),
                const Text('不再提示', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dontShowAgain) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(pdfGuideDismissedKey, true);
              }
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('打开浏览器'),
          ),
        ],
      ),
    ),
  );
}
