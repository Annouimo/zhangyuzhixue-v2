import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/widgets/question_image.dart';
import 'package:shared/widgets/question_option_row.dart';

/// 做题页统一题目容器。
///
/// 负责题目信息、回顾状态、知识标签、题干与图片的视觉层级，
/// 选择题、填空题和解答题在此基础上追加各自的交互内容。
class SolveQuestionSurface extends StatelessWidget {
  const SolveQuestionSurface({
    super.key,
    required this.stem,
    required this.questionTypeLabel,
    this.number,
    this.title,
    this.attemptSelector,
    this.isReviewMode = false,
    this.conceptTags = const [],
    this.imagePaths = const [],
    this.footer,
  });

  final String stem;
  final String questionTypeLabel;
  final String? number;
  final String? title;
  final Widget? attemptSelector;
  final bool isReviewMode;
  final List<String> conceptTags;
  final List<String> imagePaths;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final hasNumber = number != null && number!.trim().isNotEmpty;
    final hasTitle = title != null && title!.trim().isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasNumber)
                Text('第 ${number!.trim()} 题', style: textTheme.titleMedium),
              AppStatusBadge(
                label: questionTypeLabel,
                tone: AppStatusTone.primary,
                compact: true,
              ),
              ?attemptSelector,
            ],
          ),
          if (hasTitle) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              title!.trim(),
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          if (isReviewMode) ...[
            const SizedBox(height: AppSpacing.md),
            _ReviewBanner(),
          ],
          if (conceptTags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: conceptTags
                  .map(
                    (tag) => AppStatusBadge(
                      label: tag,
                      tone: AppStatusTone.neutral,
                      icon: Icons.sell_outlined,
                      compact: true,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Semantics(header: true, child: MdLatexBody(stem, fontSize: 16)),
          if (imagePaths.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...imagePaths.map(
              (path) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: QuestionImage(relativePath: path),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.infoContainer,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: colors.primaryBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: colors.onInfoContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '回顾模式 · 当前记录仅供浏览，不会修改历史答案',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onInfoContainer),
            ),
          ),
        ],
      ),
    );
  }
}

enum SolveOptionState { idle, selected, correct, incorrect, disabled }

/// 统一答案选项。
///
/// 同时通过图标、文字与颜色表达状态，避免只依赖红绿色。
class SolveAnswerOption extends StatelessWidget {
  const SolveAnswerOption({
    super.key,
    required this.label,
    required this.content,
    required this.state,
    this.onTap,
  });

  final String label;
  final String content;
  final SolveOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = _resolveScheme(colors);
    final enabled = onTap != null && state != SolveOptionState.disabled;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: state == SolveOptionState.selected,
      label: '选项 $label',
      value: switch (state) {
        SolveOptionState.correct => '正确答案',
        SolveOptionState.incorrect => '回答错误',
        SolveOptionState.selected => '已选择',
        SolveOptionState.disabled => '不可选择',
        SolveOptionState.idle => '未选择',
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasizedCurve,
        decoration: BoxDecoration(
          color: scheme.background,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: scheme.border,
            width: state == SolveOptionState.idle ? 1 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: QuestionOptionRow(
              label: label,
              content: content,
              labelWidth: 28,
              labelBuilder: (context, label) => AnimatedContainer(
                duration: AppMotion.fast,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.indicatorBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.indicatorBorder),
                ),
                child: Center(
                  child: switch (state) {
                    SolveOptionState.correct => Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: scheme.indicatorForeground,
                    ),
                    SolveOptionState.incorrect => Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: scheme.indicatorForeground,
                    ),
                    _ => Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.indicatorForeground,
                      ),
                    ),
                  },
                ),
              ),
              trailing: state == SolveOptionState.selected
                  ? Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                      color: colors.primary,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  _OptionScheme _resolveScheme(AppSemanticColors colors) {
    return switch (state) {
      SolveOptionState.selected => _OptionScheme(
        background: colors.primaryContainer,
        border: colors.primary,
        indicatorBackground: colors.primary,
        indicatorBorder: colors.primary,
        indicatorForeground: colors.onPrimary,
      ),
      SolveOptionState.correct => _OptionScheme(
        background: colors.successContainer,
        border: colors.success,
        indicatorBackground: colors.success,
        indicatorBorder: colors.success,
        indicatorForeground: colors.onSuccess,
      ),
      SolveOptionState.incorrect => _OptionScheme(
        background: colors.errorContainer,
        border: colors.error,
        indicatorBackground: colors.error,
        indicatorBorder: colors.error,
        indicatorForeground: colors.onError,
      ),
      SolveOptionState.disabled => _OptionScheme(
        background: colors.disabledBackground,
        border: colors.border,
        indicatorBackground: colors.surfaceSubtle,
        indicatorBorder: colors.border,
        indicatorForeground: colors.disabledForeground,
      ),
      SolveOptionState.idle => _OptionScheme(
        background: colors.surface,
        border: colors.border,
        indicatorBackground: colors.surfaceSubtle,
        indicatorBorder: colors.border,
        indicatorForeground: colors.textSecondary,
      ),
    };
  }
}

class _OptionScheme {
  const _OptionScheme({
    required this.background,
    required this.border,
    required this.indicatorBackground,
    required this.indicatorBorder,
    required this.indicatorForeground,
  });

  final Color background;
  final Color border;
  final Color indicatorBackground;
  final Color indicatorBorder;
  final Color indicatorForeground;
}
