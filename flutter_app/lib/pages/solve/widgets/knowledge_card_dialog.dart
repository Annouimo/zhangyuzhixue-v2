import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/md_latex_body.dart';

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
      builder: (_) => KnowledgeCardDialog(
        cardTitle: title,
        cardContent: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cardTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SingleChildScrollView(
              child: MdLatexBody(cardContent, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // 卡片掌握度反馈
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _feedbackChip(context, '完全掌握', AppColors.success),
                const SizedBox(width: 8),
                _feedbackChip(context, '了解', AppColors.warning),
                const SizedBox(width: 8),
                _feedbackChip(context, '不理解', AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackChip(BuildContext context, String label, Color color) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
