import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';

enum PdfGuideAction { open, copy }

Future<PdfGuideAction?> showPdfGuideDialog(BuildContext context) {
  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  return showDialog<PdfGuideAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.print_outlined, size: 24, color: ctx.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text('准备打印试卷', style: Theme.of(ctx).textTheme.titleLarge),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMobile
                ? '建议在电脑浏览器中打开，预览和打印效果更稳定。无需安装电脑端，复制链接发送到电脑即可。'
                : '将在浏览器中打开打印工作台，也可以复制链接发送到其他电脑。',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '链接 30 分钟内有效。页面会在字体、公式和图片准备完成后提示打印。',
            style: Theme.of(
              ctx,
            ).textTheme.bodySmall?.copyWith(color: ctx.colors.textMuted),
          ),
        ],
      ),
      actions: isMobile
          ? [
              SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            label: '取消',
                            type: AppButtonType.text,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(PdfGuideAction.open),
                            label: '仍在手机打开',
                            type: AppButtonType.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(PdfGuideAction.copy),
                      label: '复制链接，发送到电脑',
                    ),
                  ],
                ),
              ),
            ]
          : [
              AppButton(
                onPressed: () => Navigator.of(ctx).pop(),
                label: '取消',
                type: AppButtonType.text,
                expanded: false,
              ),
              AppButton(
                onPressed: () => Navigator.of(ctx).pop(PdfGuideAction.copy),
                label: '复制链接',
                type: AppButtonType.secondary,
                expanded: false,
              ),
              AppButton(
                onPressed: () => Navigator.of(ctx).pop(PdfGuideAction.open),
                label: '打开打印页面',
                expanded: false,
              ),
            ],
    ),
  );
}
