import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/theme/app_icons.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_section.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/md_latex_body.dart';

/// 判题结果卡。
class SolveResultCard extends StatelessWidget {
  const SolveResultCard({
    super.key,
    required this.isCorrect,
    this.correctAnswer,
    this.explanation,
  });

  final bool isCorrect;
  final String? correctAnswer;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = isCorrect ? AppStatusTone.success : AppStatusTone.error;
    final foreground = isCorrect
        ? colors.onSuccessContainer
        : colors.onErrorContainer;
    final background = isCorrect
        ? colors.successContainer
        : colors.errorContainer;
    final border = isCorrect ? colors.success : colors.error;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppStatusBadge(
                  label: isCorrect ? '回答正确' : '回答错误',
                  tone: tone,
                  icon: isCorrect ? AppIcons.success : AppIcons.error,
                ),
                const Spacer(),
                Text(
                  isCorrect ? '做得很好' : '看看正确答案和解析',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ],
            ),
            if (!isCorrect &&
                correctAnswer != null &&
                correctAnswer!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _ContentSection(
                title: '正确答案',
                icon: Icons.task_alt_rounded,
                foreground: foreground,
                child: MdLatexBody(correctAnswer!, fontSize: 17),
              ),
            ],
            if (explanation != null && explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _ContentSection(
                title: '答案解析',
                icon: Icons.menu_book_rounded,
                foreground: foreground,
                child: MdLatexBody(explanation!, fontSize: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 揭示型题目的答案卡。
class SolveAnswerRevealCard extends StatelessWidget {
  const SolveAnswerRevealCard({
    super.key,
    required this.answer,
    this.explanation,
  });

  final String answer;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          selected: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: AppStatusBadge(
                  label: '正确答案',
                  tone: AppStatusTone.primary,
                  icon: Icons.task_alt_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: colors.primaryBorder),
                ),
                child: MdLatexBody(answer, fontSize: 19),
              ),
            ],
          ),
        ),
        if (explanation != null && explanation!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppSection(
            title: '答案解析',
            leading: Icon(
              Icons.menu_book_rounded,
              size: 20,
              color: colors.primary,
            ),
            showDivider: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [MdLatexBody(explanation!, fontSize: 15)],
            ),
          ),
        ],
      ],
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.title,
    required this.icon,
    required this.foreground,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: foreground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
