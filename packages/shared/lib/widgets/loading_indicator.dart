import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 加载中指示器 — 支持自定义消息
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size / 8,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
