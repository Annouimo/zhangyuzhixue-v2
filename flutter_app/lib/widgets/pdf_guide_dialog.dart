import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
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
        title: Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 24,
              color: ctx.colors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('准备打印试卷', style: Theme.of(ctx).textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '试卷已生成，请在浏览器中完成打印或保存 PDF。',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '首次打开需加载印刷字体，可能需要多等几秒；页面显示“试卷已就绪”后再打印。',
              style: Theme.of(
                ctx,
              ).textTheme.bodySmall?.copyWith(color: ctx.colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('电脑用户：', style: Theme.of(ctx).textTheme.titleSmall),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('按 Ctrl+P 打开打印对话框\n选择「另存为 PDF」或直接打印'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('手机用户：', style: Theme.of(ctx).textTheme.titleSmall),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('点击浏览器菜单 (⋮) → 分享 → 打印 → 选择「保存为 PDF」'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '纸张选择 A4，取消页眉页脚',
              style: Theme.of(
                ctx,
              ).textTheme.bodySmall?.copyWith(color: ctx.colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (v) => setState(() => dontShowAgain = v ?? false),
                ),
                Text('不再提示', style: Theme.of(ctx).textTheme.bodySmall),
              ],
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            label: '取消',
            type: AppButtonType.text,
            expanded: false,
          ),
          AppButton(
            onPressed: () async {
              if (dontShowAgain) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(pdfGuideDismissedKey, true);
              }
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            label: '打开浏览器',
            expanded: false,
          ),
        ],
      ),
    ),
  );
}
