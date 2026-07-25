import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';

/// 反馈按钮类型

enum FeedbackType { fullCorrect, partialCorrect, wrong }

/// 自评反馈按钮组。
class FeedbackButtons extends StatelessWidget {
  const FeedbackButtons({
    super.key,
    this.selected,
    this.onChanged,
  });

  final FeedbackType? selected;
  final ValueChanged<FeedbackType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '这一步你掌握得怎么样？',
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;
            final items = FeedbackType.values
                .map(
                  (type) => _FeedbackChoice(
                    type: type,
                    selected: selected == type,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!.call(type),
                  ),
                )
                .toList();

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i != items.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: items[i]),
                  if (i != items.length - 1)
                    const SizedBox(width: AppSpacing.xs),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeedbackChoice extends StatelessWidget {
  const _FeedbackChoice({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final FeedbackType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, icon, color, containerColor) = switch (type) {
      FeedbackType.fullCorrect => (
          '完全掌握',
          Icons.check_circle_outline_rounded,
          colors.success,
          colors.successContainer,
        ),
      FeedbackType.partialCorrect => (
          '部分掌握',
          Icons.change_circle_outlined,
          colors.warning,
          colors.warningContainer,
        ),
      FeedbackType.wrong => (
          '还没掌握',
          Icons.replay_rounded,
          colors.error,
          colors.errorContainer,
        ),
    };

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: selected ? containerColor : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: selected ? color : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? color : colors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? color : colors.textSecondary,
                        ),
                    overflow: TextOverflow.ellipsis,
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
