import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 统一操作 Chip — 替代各地零散的 _actionChip 私有方法
///
/// 支持 emoji/icon 两种模式，边框圆角样式统一。
class ActionChipWidget extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final double fontSize;

  const ActionChipWidget({
    super.key,
    this.emoji,
    this.icon,
    required this.label,
    required this.onTap,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji!, style: TextStyle(fontSize: fontSize + 1))
            else if (icon != null)
              Icon(icon, size: fontSize + 5, color: AppColors.textSecondary),
            if (emoji != null || icon != null) const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: fontSize, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
