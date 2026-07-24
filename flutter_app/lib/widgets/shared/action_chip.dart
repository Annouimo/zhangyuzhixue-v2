import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 统一操作 Chip — 替代各地零散的 _actionChip 私有方法
///
/// 两种样式：
/// - 普通模式（默认）：带边框，灰色文字
/// - 激活模式（active=true）：填充背景色，高亮色文字
class ActionChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final Color? iconColor;

  /// 激活态：填充背景色 + 去除边框 + 高亮色
  final bool active;

  /// 激活态下的图标/文字颜色，覆盖 iconColor
  final Color? activeColor;

  const ActionChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fontSize = 11,
    this.iconColor,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? (activeColor ?? AppColors.primary) : (iconColor ?? AppColors.textSecondary);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : null,
          border: active ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: fontSize + 5, color: fg),
            const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: fontSize, color: fg)),
          ],
        ),
      ),
    );
  }
}
