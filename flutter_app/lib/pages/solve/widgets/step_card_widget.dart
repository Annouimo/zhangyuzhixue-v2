import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/md_latex_body.dart';

import '../../../data/daos/progress_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/sync/sync_manager.dart';
import '../../../data/sync/sync_types.dart';
import '../../../domain/progress_repository.dart' as progress;
import 'cooling_timer.dart';
import 'feedback_buttons.dart';
import 'knowledge_card_dialog.dart';

/// 解答题的单步学习卡。
class StepCardWidget extends StatefulWidget {
  const StepCardWidget({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    this.cooldownSeconds = 5,
    this.isRevisit = false,
    this.existingRecord,
    this.onFeedback,
    this.questionId,
    this.submissionDetailId,
  });

  final progress.Step step;
  final int stepIndex;
  final int totalSteps;
  final int cooldownSeconds;
  final bool isRevisit;
  final progress.StepSolveRecord? existingRecord;
  final ValueChanged<FeedbackType>? onFeedback;
  final int? questionId;
  final int? submissionDetailId;

  @override
  State<StepCardWidget> createState() => _StepCardWidgetState();
}

class _StepCardWidgetState extends State<StepCardWidget> {
  bool _expanded = false;
  bool _feedbackGiven = false;
  FeedbackType? _feedbackType;
  final _timerKey = GlobalKey<CoolingTimerState>();

  bool get isLast => widget.stepIndex == widget.totalSteps - 1;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _expanded = widget.existingRecord!.feedbackGiven;
      _feedbackGiven = widget.existingRecord!.feedbackGiven;
      if (widget.existingRecord!.feedbackType != null) {
        _feedbackType = _parseFeedback(widget.existingRecord!.feedbackType!);
      }
    }
    if (!widget.isRevisit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _timerKey.currentState?.start();
      });
    }
  }

  FeedbackType? _parseFeedback(String type) {
    return switch (type) {
      'full_correct' => FeedbackType.fullCorrect,
      'partial_correct' => FeedbackType.partialCorrect,
      'wrong' => FeedbackType.wrong,
      _ => null,
    };
  }

  void _toggleExpand() {
    if (!_expanded) setState(() => _expanded = true);
  }

  void _onFeedback(FeedbackType type) {
    setState(() {
      _feedbackGiven = true;
      _feedbackType = type;
    });
    widget.onFeedback?.call(type);
  }

  Future<void> _showKnowledgeCard(BuildContext context, String tag) async {
    final dao = QuestionDao(DatabaseProvider());
    final card = await dao.getKnowledgeCardByTitle(tag);
    if (!context.mounted) return;
    final feedback = await KnowledgeCardDialog.show(
      context,
      title: tag,
      content: card?.content ?? '知识卡片：$tag',
    );
    if (feedback != null && context.mounted) {
      final pDao = ProgressDao(DatabaseProvider());
      final submissionDetailId = widget.submissionDetailId ?? 0;
      final questionId = widget.questionId ?? 0;
      if (submissionDetailId > 0 && questionId > 0) {
        try {
          final fbId = await pDao.insertCardFeedback(
            submissionDetailId: submissionDetailId,
            questionId: questionId,
            cardTitle: tag,
            cardStatus: feedback,
          );
          try {
            await SyncManager().enqueue(
              entityType: SyncEntityType.cardFeedback,
              operation: SyncOperationType.upsert,
              localId: fbId,
              payload: jsonEncode({
                'submission_detail_id': null,
                'question_id': questionId,
                'card_title': tag,
                'card_status': feedback,
              }),
            );
          } catch (_) {}
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progressValue = widget.totalSteps <= 0
        ? 0.0
        : (widget.stepIndex + 1) / widget.totalSteps;

    return AppCard(
      selected: _expanded,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _feedbackGiven
                      ? colors.successContainer
                      : colors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _feedbackGiven ? colors.success : colors.primaryBorder,
                  ),
                ),
                child: Center(
                  child: _feedbackGiven
                      ? Icon(Icons.check_rounded,
                          size: 22, color: colors.success)
                      : Text(
                          '${widget.stepIndex + 1}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colors.primary,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.step.title.isEmpty
                          ? '第 ${widget.stepIndex + 1} 步'
                          : widget.step.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '步骤 ${widget.stepIndex + 1} / ${widget.totalSteps}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (_feedbackGiven)
                const AppStatusBadge(
                  label: '已完成',
                  tone: AppStatusTone.success,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progressValue.clamp(0.0, 1.0).toDouble(),
              backgroundColor: colors.surfaceSubtle,
              color: _feedbackGiven ? colors.success : colors.primary,
            ),
          ),
          if (widget.step.cardTitles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: widget.step.cardTitles
                  .map(
                    (tag) => ActionChip(
                      avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                      label: Text(tag),
                      onPressed: () => _showKnowledgeCard(context, tag),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (!_expanded && !_feedbackGiven) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              '先独立思考本步骤，倒计时结束后再展开解析。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            CoolingTimer(
              key: _timerKey,
              seconds: widget.cooldownSeconds,
              label: '可查看解析',
              child: AppButton(
                label: '查看本步解析',
                icon: Icons.visibility_rounded,
                fullWidth: true,
                onPressed: _toggleExpand,
              ),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 20, color: colors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text('步骤解析',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MdLatexBody(widget.step.analysis, fontSize: 15),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FeedbackButtons(
              selected: _feedbackType,
              onChanged: widget.isRevisit && _feedbackGiven
                  ? null
                  : _onFeedback,
            ),
            if (_feedbackGiven && isLast) ...[
              const SizedBox(height: AppSpacing.md),
              const Center(
                child: AppStatusBadge(
                  label: '全部步骤已完成',
                  tone: AppStatusTone.success,
                  icon: Icons.celebration_rounded,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
