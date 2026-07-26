import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../../data/daos/question_dao.dart';
import '../../data/daos/rating_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/rating_repository.dart';
import '../../widgets/shared/format_utils.dart';

/// 题目多维评分页。
class SolveRatePage extends StatefulWidget {
  const SolveRatePage({
    super.key,
    required this.questionId,
    this.ratingRepository,
  });

  final int questionId;
  final RatingRepository? ratingRepository;

  @override
  State<SolveRatePage> createState() => _SolveRatePageState();
}

class _SolveRatePageState extends State<SolveRatePage> {
  int _difficulty = 0;
  int _calculation = 0;
  int _elegance = 0;
  double _algoDifficulty = 0;
  double _algoCalculation = 0;
  bool _submitted = false;
  bool _saving = false;
  bool _loading = true;
  String? _error;
  double _rewardPoints = 0.3;
  late final RatingRepository _ratingRepo;

  @override
  void initState() {
    super.initState();
    _ratingRepo = widget.ratingRepository ??
        RatingRepository(
          RatingDao(DatabaseProvider()),
          QuestionDao(DatabaseProvider()),
        );
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      try {
        final cfg = SystemConfigDao(DatabaseProvider());
        _rewardPoints = await cfg.getDouble('question_rating_reward', 0.3);
      } catch (_) {}

      final rating = await _ratingRepo.getRating(widget.questionId);
      if (!mounted) return;
      setState(() {
        _algoDifficulty = rating.algorithmDifficulty;
        _algoCalculation = rating.algorithmCalculation;
        if (rating.userDifficulty != null) {
          _difficulty = rating.userDifficulty!.round();
          _calculation = rating.userCalculation?.round() ?? 5;
          _elegance = rating.userElegance?.round() ?? 5;
          _submitted = true;
        }
        _loading = false;
      });
      AuditLogger.instance.page('SolveRatePage', {
        'difficulty': _difficulty,
        'calcScore': _calculation,
      });
    } catch (e) {
      OperationLog.instance.error('solve_rate_page_load', e);
      AuditLogger.instance.error('SolveRatePage._loadRating', e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _submit() async {
    final colors = context.colors;
    setState(() => _saving = true);
    try {
      await _ratingRepo.submitRating(
        questionId: widget.questionId,
        difficulty: _difficulty.toDouble(),
        calculation: _calculation.toDouble(),
        elegance: _elegance.toDouble(),
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _saving = false;
      });
      OperationLog.instance.action(
        'rate',
        'submitted qid=${widget.questionId}',
      );
      AppToast.show(
        context,
        icon: Icons.check_circle_rounded,
        message: '评分已提交！+$_rewardPoints 赠送积分',
        backgroundColor: colors.success,
      );
    } catch (e) {
      OperationLog.instance.error('solve_rate_page_load', e);
      AuditLogger.instance.error('SolveRatePage._submit', e);
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(
        context,
        icon: Icons.error_rounded,
        message: '评分提交失败，请重试',
        backgroundColor: colors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('题目评分')),
      body: _loading
          ? const LoadingIndicator(message: '正在读取评分')
          : _error != null
              ? ErrorPlaceholder(
                  message: '评分信息加载失败，请检查后重试',
                  onRetry: () {
                    setState(() {
                      _error = null;
                      _loading = true;
                    });
                    _loadRating();
                  },
                )
              : AppContentContainer(
                  maxWidth: AppContentWidth.reading,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppStatusBadge(
                                label: '完成后反馈',
                                tone: AppStatusTone.recommendation,
                                icon: Icons.star_rounded,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '请为这道题打分',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '你的真实感受会帮助其他同学更准确地判断题目难度和学习成本。',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StarRating(
                          label: '理解难度',
                          description: '理解题意和找到解法有多困难',
                          value: _difficulty,
                          algorithmScore:
                              _algoDifficulty > 0 ? _algoDifficulty : null,
                          max: 10,
                          onChanged: _submitted
                              ? null
                              : (value) =>
                                  setState(() => _difficulty = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StarRating(
                          label: '计算量',
                          description: '实际推导、运算和书写工作量',
                          value: _calculation,
                          algorithmScore:
                              _algoCalculation > 0 ? _algoCalculation : null,
                          max: 10,
                          onChanged: _submitted
                              ? null
                              : (value) =>
                                  setState(() => _calculation = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StarRating(
                          label: '解法优雅度',
                          description: '解法是否简洁、自然且具有启发性',
                          value: _elegance,
                          max: 10,
                          onChanged: _submitted
                              ? null
                              : (value) => setState(() => _elegance = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '评分可跳过，不影响学习记录；算法评分仅作为参考。',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_submitted)
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                const AppStatusBadge(
                                  label: '评分已提交',
                                  tone: AppStatusTone.success,
                                ),
                                const Spacer(),
                                AppButton(
                                  label: '修改评分',
                                  icon: Icons.edit_outlined,
                                  variant: AppButtonVariant.text,
                                  fullWidth: false,
                                  onPressed: () =>
                                      setState(() => _submitted = false),
                                ),
                              ],
                            ),
                          )
                        else
                          AppButton(
                            label: '提交评分（+$_rewardPoints 赠送积分）',
                            icon: Icons.send_rounded,
                            fullWidth: true,
                            isLoading: _saving,
                            onPressed: _saving ? null : _submit,
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.label,
    required this.description,
    required this.value,
    required this.max,
    required this.onChanged,
    this.algorithmScore,
  });

  final String label;
  final String description;
  final int value;
  final int max;
  final double? algorithmScore;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (algorithmScore != null && algorithmScore! > 0)
                AppStatusBadge(
                  label: '算法 ${formatAmount(algorithmScore!)}',
                  tone: AppStatusTone.info,
                  icon: Icons.auto_awesome_rounded,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xs,
            children: List.generate(max, (index) {
              final score = index + 1;
              final filled = score <= value;
              return Semantics(
                button: onChanged != null,
                selected: filled,
                label: '$label $score 分',
                child: IconButton(
                  tooltip: '$score 分',
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(score),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? colors.warning
                        : colors.disabledForeground,
                    size: 30,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value > 0 ? '$value / $max' : '尚未评分',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: value > 0 ? colors.warning : colors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
