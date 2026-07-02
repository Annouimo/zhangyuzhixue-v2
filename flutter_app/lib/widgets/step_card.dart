import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 单个步骤卡片
class StepCard extends StatelessWidget {
  final int stepNumber;
  final String analysis;
  final List<String> knowledgeCards;
  final bool showAnalysis;
  final VoidCallback onTap;
  final Widget? feedbackWidget;

  const StepCard({
    super.key,
    required this.stepNumber,
    this.analysis = '',
    this.knowledgeCards = const [],
    this.showAnalysis = false,
    required this.onTap,
    this.feedbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 步骤标题
              Text('第 $stepNumber 步', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSizeTitle)),
              const SizedBox(height: 8),
              // 知识卡片列表（始终可见）
              ...knowledgeCards.map((kc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(kc, style: const TextStyle(color: AppTheme.primaryColor, fontSize: AppTheme.fontSizeSmall)),
                    ],
                  ),
                ),
              )),
              // 解析文本（条件显示）
              if (showAnalysis && analysis.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 6),
                Text(analysis, style: const TextStyle(height: 1.6, fontSize: AppTheme.fontSizeBody)),
              ],
              // 反馈按钮（条件显示）
              if (showAnalysis && feedbackWidget != null) ...[
                const SizedBox(height: 8),
                feedbackWidget!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
