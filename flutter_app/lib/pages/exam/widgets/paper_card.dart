import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 组卷卡片（列表页复用：我的组卷/发现/收藏）
///
/// 支持底部操作行（actions）和尾部可选 widget（trailingWidget）。
class PaperCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final Widget? trailingWidget;
  final List<Widget>? actions;

  const PaperCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.trailingWidget,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.article_outlined, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  if (trailingWidget != null) trailingWidget!
                  else if (trailing != null) Text(trailing!, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: actions!),
              ),
            ),
        ],
      ),
    );
  }
}
