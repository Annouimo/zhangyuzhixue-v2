import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 空状态占位
class EmptyPlaceholder extends StatelessWidget {
  final String message;
  final String? icon;

  const EmptyPlaceholder({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon ?? '📭',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
