import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 反馈按钮类型
enum FeedbackType { fullCorrect, partialCorrect, wrong }

/// 反馈按钮组 — FullCorrect / PartialCorrect / Wrong
class FeedbackButtons extends StatelessWidget {
  final FeedbackType? selected;
  final ValueChanged<FeedbackType>? onChanged;

  const FeedbackButtons({
    super.key,
    this.selected,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: FeedbackType.values.map((type) {
        final isSelected = selected == type;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _FeedbackChip(
            type: type,
            selected: isSelected,
            onTap: () => onChanged?.call(type),
          ),
        );
      }).toList(),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final FeedbackType type;
  final bool selected;
  final VoidCallback onTap;

  const _FeedbackChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      FeedbackType.fullCorrect => ('全对', AppColors.success),
      FeedbackType.partialCorrect => ('部分对', AppColors.warning),
      FeedbackType.wrong => ('不对', AppColors.error),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: color, width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
