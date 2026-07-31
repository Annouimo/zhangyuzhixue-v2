import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_state_panel.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../../data/daos/achievement_dao.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/achievement_repository.dart';

/// 学习成就与解锁进度。
class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key, this.achievementRepository});

  final AchievementRepository? achievementRepository;

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  late final AchievementRepository _repo;
  bool _loading = true;
  String? _error;
  List<AchievementCategory>? _categories;
  AchievementSummary? _summary;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.achievementRepository ??
        AchievementRepository(
          AchievementDao(DatabaseProvider()),
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _repo.getSummary();
      final categories = await _repo.getCategories();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _categories = categories;
        _loading = false;
      });
      AuditLogger.instance.page('AchievementPage', {
        'unlocked': summary.unlockedCount,
        'total': summary.totalCount,
      });
    } catch (error) {
      OperationLog.instance.error('achievement_page_load', error);
      AuditLogger.instance.error('AchievementPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '正在整理成就进度…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }

    final summary = _summary;
    final categories = _categories ?? [];
    if (summary == null || categories.isEmpty) {
      return const AppStatePanel(
        title: '暂无成就数据',
        message: '完成练习、签到和组卷后，新的成就会出现在这里。',
        tone: AppStateTone.empty,
        icon: Icons.emoji_events_outlined,
      );
    }

    final progress = summary.totalCount == 0
        ? 0.0
        : summary.unlockedCount / summary.totalCount;

    return AppContentContainer(
      maxWidth: AppContentWidth.dashboard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          AppSectionHeader(
            title: '成就进度',
            subtitle: '已解锁 ${summary.unlockedCount} / ${summary.totalCount}',
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...categories.map(_buildCategory),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCategory(AchievementCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: category.label,
            subtitle:
                '已解锁 ${category.list.where((item) => item.status == 'unlocked').length} / ${category.list.length}',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= AppBreakpoints.expanded
                  ? 3
                  : constraints.maxWidth >= AppBreakpoints.compact
                  ? 2
                  : 1;
              final spacing = AppSpacing.sm;
              final width = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: category.list
                    .map(
                      (achievement) => SizedBox(
                        width: width,
                        child: _AchievementCard(achievement: achievement),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementItem achievement;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unlocked = achievement.status == 'unlocked';
    final inProgress = achievement.status == 'in_progress';
    final tone = unlocked
        ? AppStatusTone.success
        : inProgress
        ? AppStatusTone.warning
        : AppStatusTone.neutral;
    final statusLabel = unlocked
        ? '已解锁'
        : inProgress
        ? '进行中'
        : '未解锁';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: unlocked
                      ? colors.successContainer
                      : colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Text(
                  achievement.iconEmoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(label: statusLabel, tone: tone, compact: true),
            ],
          ),
          if (inProgress) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (achievement.progressPercent / 100).clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  achievement.isAccuracyRate
                      ? '${achievement.progress}% / ${achievement.threshold}%'
                      : '${achievement.progress}/${achievement.threshold}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
          if (unlocked && achievement.unlockedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${achievement.unlockedAt} 解锁',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.success),
            ),
          ],
        ],
      ),
    );
  }
}
