import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 空状态占位
class EmptyPlaceholder extends StatelessWidget {
  final String message;
  final IconData? icon;

  EmptyPlaceholder({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.mail_outline,
            size: 48,
            color: colors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
