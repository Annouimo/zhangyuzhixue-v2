import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 统一操作 Chip — 替代各地零散的 _actionChip 私有方法
///
/// 使用 Material Icon，边框圆角样式统一。
class ActionChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final Color? iconColor;

  const ActionChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fontSize = 11,
    this.iconColor,
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
            Icon(icon, size: fontSize + 5, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: fontSize, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
