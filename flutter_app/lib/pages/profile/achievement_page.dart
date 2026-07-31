import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_state_panel.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/filter_panel_components.dart';
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
  _AchievementFilter _filter = _AchievementFilter.all;

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
    final all = categories.expand((category) => category.list).toList();
    final unlocked = all.where((item) => item.status == 'unlocked').length;
    final inProgress = all.where((item) => item.status == 'in_progress').length;
    final locked = all.where((item) => item.status == 'locked').length;
    final filteredCount = all.where(_matchesFilter).length;
    final filterLabels = <_AchievementFilter, String>{
      _AchievementFilter.all: '全部 ${all.length}',
      _AchievementFilter.unlocked: '已解锁 $unlocked',
      _AchievementFilter.inProgress: '进行中 $inProgress',
      _AchievementFilter.locked: '未解锁 $locked',
    };
    final nearest = all
        .where((item) => item.status != 'unlocked')
        .fold<AchievementItem?>(
          null,
          (best, item) =>
              best == null || item.progressPercent > best.progressPercent
              ? item
              : best,
        );

    return AppContentContainer(
      maxWidth: AppContentWidth.dashboard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '成就进度',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${summary.unlockedCount} / ${summary.totalCount}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
          if (nearest != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '最近可达成：${nearest.name}，还差 ${_remainingText(nearest)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilterChoiceGroup(
            label: '',
            options: filterLabels.values.toList(),
            selected: {filterLabels[_filter]!},
            onChanged: (label, _) {
              final value = filterLabels.entries
                  .firstWhere((entry) => entry.value == label)
                  .key;
              setState(() => _filter = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (filteredCount == 0)
            const AppStatePanel(
              title: '暂无此状态的成就',
              message: '切换其他状态查看成就。',
              tone: AppStateTone.empty,
              icon: Icons.emoji_events_outlined,
            )
          else
            ...categories.map(_buildCategory),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _remainingText(AchievementItem item) {
    final remaining = (item.threshold - item.progress).clamp(0, item.threshold);
    return item.isAccuracyRate ? '$remaining 个百分点' : '$remaining';
  }

  bool _matchesFilter(AchievementItem item) => switch (_filter) {
    _AchievementFilter.all => true,
    _AchievementFilter.unlocked => item.status == 'unlocked',
    _AchievementFilter.inProgress => item.status == 'in_progress',
    _AchievementFilter.locked => item.status == 'locked',
  };

  Widget _buildCategory(AchievementCategory category) {
    final achievements = category.list.where(_matchesFilter).toList();
    if (achievements.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: _categoryLabel(category.label)),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 840 ? 2 : 1;
              final spacing = AppSpacing.sm;
              final width = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: achievements
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

  String _categoryLabel(String source) {
    final label = source
        .replaceFirst(RegExp(r'^[^\u4e00-\u9fffA-Za-z0-9]+'), '')
        .trim();
    if (label.endsWith('成就')) return label;
    return '$label成就';
  }
}

enum _AchievementFilter { all, unlocked, inProgress, locked }

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementItem achievement;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unlocked = achievement.status == 'unlocked';
    final inProgress = achievement.status == 'in_progress';
    final locked = !unlocked && !inProgress;

    return AppCard(
      selected: inProgress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? colors.successContainer : colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: locked
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.33,
                      0.33,
                      0.33,
                      0,
                      0,
                      0.33,
                      0.33,
                      0.33,
                      0,
                      0,
                      0.33,
                      0.33,
                      0.33,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: Text(
                      achievement.iconEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  )
                : Text(
                    achievement.iconEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: locked ? colors.textMuted : null),
                      ),
                    ),
                    Icon(
                      unlocked
                          ? Icons.check_circle_rounded
                          : locked
                          ? Icons.lock_outline_rounded
                          : Icons.timelapse_rounded,
                      size: 18,
                      color: unlocked
                          ? colors.success
                          : locked
                          ? colors.textMuted
                          : colors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: locked ? colors.textMuted : colors.textSecondary,
                  ),
                ),
                if (inProgress) ...[
                  const SizedBox(height: AppSpacing.sm),
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
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        achievement.isAccuracyRate
                            ? '${achievement.progress}% / ${achievement.threshold}%'
                            : '${achievement.progress} / ${achievement.threshold}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
                if (unlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${achievement.unlockedAt} 解锁',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
