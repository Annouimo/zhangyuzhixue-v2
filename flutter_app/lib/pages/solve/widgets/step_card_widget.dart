import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../domain/progress_repository.dart' as progress;
import '../../../widgets/md_latex_body.dart';
import '../../../data/daos/progress_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/sync/sync_manager.dart';
import '../../../data/sync/sync_types.dart';
import 'cooling_timer.dart';
import 'feedback_buttons.dart';
import 'knowledge_card_dialog.dart';

/// 解答步骤卡
class StepCardWidget extends StatefulWidget {
  final progress.Step step;
  final int stepIndex;
  final int totalSteps;
  final int cooldownSeconds;
  final bool isRevisit;
  final progress.StepSolveRecord? existingRecord;
  final ValueChanged<FeedbackType>? onFeedback;
  final int? questionId;
  final int? submissionDetailId;

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
    switch (type) {
      case 'full_correct': return FeedbackType.fullCorrect;
      case 'partial_correct': return FeedbackType.partialCorrect;
      case 'wrong': return FeedbackType.wrong;
      default: return null;
    }
  }

  void _toggleExpand() {
    if (!_expanded) setState(() => _expanded = true);
  }

  void _onFeedback(FeedbackType type) {
    setState(() { _feedbackGiven = true; _feedbackType = type; });
    widget.onFeedback?.call(type);
  }

  Future<void> _showKnowledgeCard(BuildContext context, String tag) async {
    final dao = QuestionDao(DatabaseProvider().assetsDb);
    final card = await dao.getKnowledgeCardByTitle(tag);
    if (!context.mounted) return;
    final feedback = await KnowledgeCardDialog.show(
      context,
      title: tag,
      content: card?.content ?? '知识卡片：$tag',
    );
    // 如果用户选择了反馈，保存到数据库
    if (feedback != null && context.mounted) {
      final pDao = ProgressDao(DatabaseProvider().appDb);
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
          // 入同步队列
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: _expanded ? Border.all(color: AppColors.primary.withValues(alpha:0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题 + 知识标签
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _feedbackGiven ? AppColors.primary : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text('${widget.stepIndex + 1}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _feedbackGiven ? Colors.white : AppColors.primary),
              )),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.step.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            )),
            ...widget.step.cardTitles.take(2).map((tag) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => _showKnowledgeCard(context, tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag.length > 6 ? '${tag.substring(0, 6)}…' : tag,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 10),
          if (!_expanded && !_feedbackGiven)
            CoolingTimer(
              key: _timerKey,
              seconds: widget.cooldownSeconds,
              child: ElevatedButton.icon(
                onPressed: _toggleExpand,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(isLast ? '查看解析' : '下一步'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(140, 38)),
              ),
            ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: MdLatexBody(widget.step.analysis, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (!_feedbackGiven)
              FeedbackButtons(onChanged: _onFeedback)
            else if (widget.isRevisit)
              FeedbackButtons(selected: _feedbackType)
            else
              FeedbackButtons(selected: _feedbackType, onChanged: _onFeedback),
            if (_feedbackGiven && isLast)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Text('✅', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text('该题全部步骤已完成',
                    style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
          ],
        ],
      ),
    );
  }
}
