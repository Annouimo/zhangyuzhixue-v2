import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/widgets/app_dialog.dart';

/// 知识卡片弹层
class KnowledgeCardDialog extends StatelessWidget {
  final String cardTitle;
  final String cardContent;

  const KnowledgeCardDialog({
    super.key,
    required this.cardTitle,
    required this.cardContent,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          KnowledgeCardDialog(cardTitle: title, cardContent: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewport = MediaQuery.sizeOf(context);
    return AppDialogFrame(
      size: AppDialogSize.wide,
      child: ConstrainedBox(
        key: const Key('knowledge-card-surface'),
        constraints: BoxConstraints(
          maxWidth: AppContentWidth.reading,
          maxHeight: viewport.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      cardTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭知识卡片',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Flexible(
                child: SingleChildScrollView(
                  child: MdLatexBody(cardContent, fontSize: 15),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '这张知识卡你掌握得怎么样？',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _feedbackChip(context, '完全掌握', colors.success),
                  _feedbackChip(context, '了解', colors.warning),
                  _feedbackChip(context, '不理解', colors.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackChip(BuildContext context, String label, Color color) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(label),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
