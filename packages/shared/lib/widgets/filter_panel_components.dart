import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FilterPanelSummary extends StatelessWidget {
  final List<String> labels;
  final List<String> emptyHints;

  const FilterPanelSummary({
    super.key,
    required this.labels,
    required this.emptyHints,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget badge(String text, {bool warning = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: warning
            ? colors.warning.withValues(alpha: 0.15)
            : colors.primaryContainer,
        borderRadius: BorderRadius.circular(4),
        border: warning
            ? Border.all(color: colors.warning.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: warning ? colors.warning : colors.primary,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: labels.map(badge).toList(),
            ),
          ),
        if (emptyHints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: emptyHints
                  .map((hint) => badge(hint, warning: true))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class FilterPanelSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? trailing;

  const FilterPanelSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColoredBox(
          color: colors.background,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class FilterChoiceGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final Set<String> selected;
  final String Function(String option)? labelFor;
  final void Function(String option, bool selected) onChanged;

  const FilterChoiceGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(
                labelFor?.call(option) ?? option,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (value) => onChanged(option, value),
              selectedColor: colors.primaryContainer,
              checkmarkColor: colors.primary,
              side: isSelected
                  ? BorderSide.none
                  : BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class FilterRangeSegment {
  final double max;
  final String label;
  final String sample;

  const FilterRangeSegment({
    required this.max,
    required this.label,
    required this.sample,
  });
}

class FilterRangeDescription extends StatelessWidget {
  final List<FilterRangeSegment> segments;
  final double lower;
  final double upper;

  const FilterRangeDescription({
    super.key,
    required this.segments,
    required this.lower,
    required this.upper,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    int segmentIndex(double value) =>
        segments.indexWhere((segment) => value <= segment.max);
    final minIndex = segmentIndex(lower).clamp(0, segments.length - 1);
    final maxIndex = segmentIndex(upper).clamp(0, segments.length - 1);

    Widget description(int index, {String prefix = ''}) => Text.rich(
      TextSpan(
        children: [
          if (prefix.isNotEmpty)
            TextSpan(
              text: prefix,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          TextSpan(
            text: segments[index].label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
          TextSpan(
            text: ' ${segments[index].sample}',
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: minIndex == maxIndex
          ? description(minIndex)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                description(minIndex, prefix: '← '),
                description(maxIndex, prefix: '→ '),
              ],
            ),
    );
  }
}
