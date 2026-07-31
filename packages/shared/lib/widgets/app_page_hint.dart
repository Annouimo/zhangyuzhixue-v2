import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Lightweight, non-status guidance shown between a page header and its content.
class AppPageHint extends StatelessWidget {
  const AppPageHint({
    super.key,
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(child: Text(message, style: textStyle)),
        ],
      ),
    );
  }
}
