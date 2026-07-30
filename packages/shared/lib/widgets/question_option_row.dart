import 'package:flutter/material.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/md_latex_body.dart';

/// A stable two-column layout for a choice label and Markdown/LaTeX content.
///
/// Keeping the label outside the content renderer gives wrapped lines a
/// consistent hanging indent and avoids per-screen baseline offsets.
class QuestionOptionRow extends StatelessWidget {
  const QuestionOptionRow({
    super.key,
    required this.label,
    required this.content,
    this.fontSize = 15,
    this.labelWidth = 28,
    this.gap = AppSpacing.sm,
    this.labelStyle,
    this.labelBuilder,
    this.trailing,
  });

  static const labelRegionKey = ValueKey('question-option-label-region');
  static const contentRegionKey = ValueKey('question-option-content-region');

  final String label;
  final String content;
  final double fontSize;
  final double labelWidth;
  final double gap;
  final TextStyle? labelStyle;
  final Widget Function(BuildContext context, String label)? labelBuilder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel =
        labelBuilder?.call(context, label) ??
        Text(
          label,
          style: labelStyle ?? Theme.of(context).textTheme.titleSmall,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          key: labelRegionKey,
          width: labelWidth,
          child: Align(alignment: Alignment.topLeft, child: resolvedLabel),
        ),
        SizedBox(width: gap),
        Expanded(
          key: contentRegionKey,
          child: MdLatexBody(content.trim(), fontSize: fontSize),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
      ],
    );
  }
}
