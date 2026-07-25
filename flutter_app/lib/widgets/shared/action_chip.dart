import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// 统一的小型操作按钮。
class ActionChipWidget extends StatelessWidget {
  const ActionChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fontSize = 12,
    this.iconColor,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final Color? iconColor;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = active
        ? (activeColor ?? colors.primary)
        : (iconColor ?? colors.textSecondary);

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: active ? colors.primaryContainer : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: active ? colors.primaryBorder : colors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: fontSize + 5, color: foreground),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontSize: fontSize,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
