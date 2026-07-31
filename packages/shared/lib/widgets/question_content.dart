import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'md_latex_body.dart';
import 'question_image.dart';
import 'question_option_row.dart';

/// 不附带卡片背景的标准题目内容。
///
/// 页面负责标题、状态和外部布局；本组件统一题干、配图和选项的顺序与间距。
class QuestionContent extends StatelessWidget {
  const QuestionContent({
    super.key,
    required this.stem,
    this.imagePaths = const [],
    this.options = const {},
  });

  final String stem;
  final List<String> imagePaths;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MdLatexBody(stem, fontSize: 16),
        for (final path in imagePaths) ...[
          const SizedBox(height: AppSpacing.md),
          QuestionImage(relativePath: path),
        ],
        if (options.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          for (final option in options.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: QuestionOptionRow(
                label: option.key,
                content: option.value,
                fontSize: 15,
              ),
            ),
        ],
      ],
    );
  }
}
