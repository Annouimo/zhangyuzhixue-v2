import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column;
import 'router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/theme/app_icons.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/achievement_unlock_dialog.dart';
import '../domain/achievement_repository.dart';
import '../data/database/database_provider.dart';
import '../data/daos/achievement_dao.dart';
import '../data/daos/exam_dao.dart';
import '../data/api/api_client.dart';
import '../data/api/user_api.dart';
import '../data/daos/user_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/prefs/app_prefs.dart';
import '../domain/user_repository.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../data/daos/sync_queue_dao.dart';
import '../data/network/connectivity_monitor.dart';
import '../data/database/app_database.dart' as app_db;
import '../widgets/shared/format_utils.dart';
import '../domain/question_repository.dart';

/// 首页（匹配 HTML 原型 index.html — 看板式布局）
class IndexPage extends StatefulWidget {
  final UserRepository? userRepository;
  const IndexPage({super.key, this.userRepository});

  @override
  State<IndexPage> createState() => IndexPageState();
}

class IndexPageState extends State<IndexPage> {
  late final UserRepository _repo;
  bool _loading = true;
  int _pendingCount = 0;
  int _streakDays = 0;
  bool _checkedIn = false;
  bool _submitting = false;
  String? _error;
  String _levelProgress = '';
  int _currentLevel = 1;
  double _todayEarned = 0;
  int _todayTotal = 0;
  int _todayCorrect = 0;
  int _syncPendingCount = 0;
  bool _showWelcomeHint = false;

  static const List<String> _welcomeMessages = [
    '每一次练习，都在为高考蓄力 💪',
    '一天一道好题，高考水到渠成 📚',
    '数学没有捷径，但每一步都算数 ✨',
    '欢迎回来，继续你的数学之旅 🌟',
    '又见面啦，今天状态怎么样？🤔',
    '今天的目标：搞懂一个薄弱知识点 🎯',
    '坐下来，打开一道题，就是最好的开始 ✏️',
    '别想太多，先做一道看看 👀',
    '解出一道难题的快感，试过就知道 😎',
    '数学是思维的体操，一起动起来吧 🏃',
  ];

  late final String _welcomeText;

  /// 供 MainShell 切 Tab 时调用：刷新首页数据
  void reload() => _load();

  @override
  void initState() {
    super.initState();
    _welcomeText = _welcomeMessages[Random().nextInt(_welcomeMessages.length)];
    _repo =
        widget.userRepository ??
        UserRepository(
          UserDao(DatabaseProvider()),
          UserApi(ApiClient()),
          QuestionDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // 每日初始化：检测跨天，重置签到状态 + 写入登录日志
      final lastDate = prefs.getString('last_checkin_date');
      if (lastDate != today) {
        await prefs.setBool('checked_in_today', false);
        await prefs.setString('last_checkin_date', today);
        // 注意：签到日志不应在此处写入，否则每次跨天首次打开 App 都会自动插入 today 的签到记录，
        // 导致本地 getLoginStreak() 推算的连续签到天数虚增。
        // 签到日志只在用户实际点击签到按钮并成功调用 API 后写入（见 _doCheckin）。
      }

      final checkedIn = prefs.getBool('checked_in_today') ?? false;
      final pending = AppPrefs().pendingHomeworkCount;

      // 新手提示：前 3 次打开显示引导卡片
      final hintCount = prefs.getInt('welcome_hint_count') ?? 0;
      if (hintCount < 3) {
        await prefs.setInt('welcome_hint_count', hintCount + 1);
        _showWelcomeHint = true;
      }

      // 通过 AchievementDao 从登录日志推算连续签到天数
      final dao = AchievementDao(DatabaseProvider());
      final streak = await dao.getLoginStreak();

      // 并行加载 4 项独立数据（Future.wait 替代串行 await）
      final results = await Future.wait([
        _repo.getLevelAndProgress(),
        _repo.todayPoints(),
        _repo.getTodaySubmissionStats(),
        SyncQueueDao(DatabaseProvider()).getPendingCount().catchError((_) => 0),
      ]);
      final lvData = results[0] as ({int level, String progress});
      final todayEarned = results[1] as double;
      final stats = results[2] as ({int total, int correct});
      final syncPending = results[3] as int;

      if (!mounted) return;
      setState(() {
        _pendingCount = pending;
        _streakDays = streak;
        _checkedIn = checkedIn;
        _levelProgress = lvData.progress;
        _currentLevel = lvData.level;
        _todayEarned = todayEarned;
        _todayTotal = stats.total;
        _todayCorrect = stats.correct;
        _syncPendingCount = syncPending;
        _loading = false;
      });
      AuditLogger.instance.page('IndexPage', {
        'streakDays': _streakDays,
        'pendingCount': _pendingCount,
        'checkedIn': _checkedIn,
        'level': _currentLevel,
      });

      // 任务奖励检测（UI 已显示后再异步执行，不阻塞首屏）
      Future.microtask(() async {
        try {
          final tasks = UserRepository.computeTodayTasks(
            stats.total,
            stats.correct,
          );
          for (var i = 0; i < tasks.length; i++) {
            if (tasks[i].done &&
                prefs.getString('task_reward_${i}_date') != today) {
              await prefs.setString('task_reward_${i}_date', today);
              final now = DateTime.now().toIso8601String();
              final newId = await DatabaseProvider().appDb
                  .into(DatabaseProvider().appDb.pointsTransactions)
                  .insert(
                    app_db.PointsTransactionsCompanion(
                      amount: Value(tasks[i].reward),
                      source: const Value('TASK_REWARD'),
                      transactionType: const Value('EARN'),
                      createdAt: Value(now),
                      description: Value('完成任务: ${tasks[i].label}'),
                    ),
                  );
              try {
                await SyncManager().enqueue(
                  entityType: SyncEntityType.pointsTransaction,
                  operation: SyncOperationType.upsert,
                  localId: newId,
                  payload: jsonEncode({
                    'amount': tasks[i].reward,
                    'source': 'TASK_REWARD',
                    'transaction_type': 'EARN',
                    'description': '完成任务: ${tasks[i].label}',
                    'created_at': now,
                  }),
                );
              } catch (_) {}
              if (!mounted) return;
              AppToast.show(
                context,
                icon: Icons.task_alt,
                message: '${tasks[i].label} 完成！+${tasks[i].reward} 赠送积分',
              );
            }
          }
          // 全部任务完成提示
          if (mounted && tasks.every((t) => t.done)) {
            AppToast.show(
              context,
              icon: Icons.celebration,
              message: '🎉 全部每日任务已完成！今日额外 +1.0 赠送积分',
            );
          }
        } catch (_) {}
      });

      // 等级检测：如果等级提升，弹出升级弹窗
      if (_currentLevel > AppPrefs().lastKnownLevel) {
        final oldLevel = AppPrefs().lastKnownLevel;
        final prefs = AppPrefs();
        await prefs.setLastKnownLevel(_currentLevel);
        try {
          final pctl = await _repo.levelPercentile();
          if (mounted) {
            showLevelUpDialog(
              context,
              oldLevel: oldLevel,
              newLevel: _currentLevel,
              percentile: pctl,
            );
          }
        } catch (_) {
          if (mounted) {
            showLevelUpDialog(
              context,
              oldLevel: oldLevel,
              newLevel: _currentLevel,
              percentile: 0,
            );
          }
        }
      } else if (_currentLevel > 0 && AppPrefs().lastKnownLevel == 0) {
        // 首次加载，初始化缓存
        await AppPrefs().setLastKnownLevel(_currentLevel);
      }

      // 成就检测：如果有新解锁的成就，弹出通知
      final prevCount = AppPrefs().lastKnownUnlockCount;
      if (prevCount > 0) {
        try {
          final achieveRepo = AchievementRepository(
            AchievementDao(DatabaseProvider()),
            QuestionDao(DatabaseProvider()),
            ExamDao(DatabaseProvider()),
          );
          await achieveRepo.getCategories();
          final newUnlocks = achieveRepo.lastNewUnlocks;
          if (newUnlocks != null && newUnlocks.isNotEmpty && mounted) {
            await AppPrefs().setLastKnownUnlockCount(
              prevCount + newUnlocks.length,
            );
            showAchievementUnlockDialog(context, achievement: newUnlocks.last);
          }
        } catch (_) {}
      } else {
        // 首次加载：初始化缓存（不弹窗）
        try {
          final achieveRepo = AchievementRepository(
            AchievementDao(DatabaseProvider()),
            QuestionDao(DatabaseProvider()),
            ExamDao(DatabaseProvider()),
          );
          final summary = await achieveRepo.getSummary();
          await AppPrefs().setLastKnownUnlockCount(summary.unlockedCount);
        } catch (_) {}
      }
    } catch (e) {
      OperationLog.instance.error('IndexPage._load', e);
      AuditLogger.instance.error('IndexPage._load', e);
      if (!mounted) return;
      setState(() {
        _error = '加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _doCheckin() async {
    final colors = context.colors;
    if (_checkedIn || _submitting) {
      if (_checkedIn)
        AppToast.show(context, icon: Icons.info_outline, message: '今天已签到');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _repo.checkin();
      final streak = result['streak_days'] as int? ?? 0;
      final points = (result['points_earned'] as num?)?.toDouble() ?? 0.0;

      // 记录本地签到状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checked_in_today', true);

      // 写入本地登录日志，供下次启动推算连续天数
      final now = DateTime.now();
      final loginDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await AchievementDao(
        DatabaseProvider(),
      ).insertLoginLog(loginDate: loginDate, createdAt: now.toIso8601String());

      if (!mounted) return;
      // 在本地创建签到积分流水（服务端已创建，本地镜像）
      try {
        final now = DateTime.now();
        await DatabaseProvider().appDb
            .into(DatabaseProvider().appDb.pointsTransactions)
            .insert(
              app_db.PointsTransactionsCompanion(
                amount: Value(points),
                source: const Value('LOGIN_BONUS'),
                transactionType: const Value('EARN'),
                createdAt: Value(now.toIso8601String()),
                description: Value('第$streak天签到奖励'),
              ),
            );
      } catch (_) {}
      setState(() {
        _streakDays = streak;
        _checkedIn = true;
        _submitting = false;
      });
      OperationLog.instance.action(
        'checkin',
        'ok +$points pts, streak=$streak',
      );
      AppToast.show(
        context,
        icon: Icons.local_fire_department,
        message: '签到成功！连续第 $streak 天 · +$points 赠送积分',
        backgroundColor: colors.success,
      );

      // 签到后重新检测等级（积分可能触发升级）
      final oldLevel = AppPrefs().lastKnownLevel;
      if (oldLevel > 0) {
        try {
          final newLevel = await _repo.currentLevel();
          if (newLevel > oldLevel && mounted) {
            await AppPrefs().setLastKnownLevel(newLevel);
            final pctl = await _repo.levelPercentile();
            if (mounted) {
              showLevelUpDialog(
                context,
                oldLevel: oldLevel,
                newLevel: newLevel,
                percentile: pctl,
              );
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      OperationLog.instance.error('IndexPage._doCheckin', e);
      AuditLogger.instance.error('IndexPage._doCheckin', e);
      if (!mounted) return;
      AppToast.show(
        context,
        icon: Icons.warning,
        message: '签到失败，请检查网络',
        backgroundColor: colors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: _loading
          ? const LoadingIndicator(message: '正在整理今天的学习计划…')
          : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : AppContentContainer(
              maxWidth: AppContentWidth.dashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xl,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildDashboard(constraints.maxWidth);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildDashboard(double width) {
    final useTwoColumns = width >= AppBreakpoints.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(compact: width < AppBreakpoints.medium),
        if (_showWelcomeHint) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildWelcomeHint(),
        ],
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: '今日概览', subtitle: '用几个关键数字快速了解当前学习状态'),
        const SizedBox(height: AppSpacing.sm),
        _buildOverviewGrid(width),
        const SizedBox(height: AppSpacing.lg),
        if (useTwoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildLearningResources()),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 6, child: _buildCheckinCard()),
            ],
          )
        else ...[
          _buildLearningResources(),
          const SizedBox(height: AppSpacing.md),
          _buildCheckinCard(),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildSyncStatus(),
      ],
    );
  }

  Widget _buildHero({required bool compact}) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStatusBadge(
          label: _todayTotal > 0 ? '今日已练 $_todayTotal 题' : '今天，从一道题开始',
          tone: AppStatusTone.primary,
          icon: Icons.bolt_rounded,
          compact: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _welcomeText,
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _pendingCount > 0
              ? '你还有 $_pendingCount 项作业待完成，也可以先用一道快速练习进入状态。'
              : '今日待办已清爽，可以继续巩固薄弱知识点。',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ],
    );

    final action = AppButton(
      label: '开始快速练习',
      icon: Icons.play_arrow_rounded,
      onPressed: _startQuickPractice,
      fullWidth: compact,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: colors.primaryBorder),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                action,
              ],
            )
          : Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.lg),
                action,
              ],
            ),
    );
  }

  Widget _buildOverviewGrid(double width) {
    final colors = context.colors;
    final accuracy = _todayTotal == 0
        ? 0
        : ((_todayCorrect / _todayTotal) * 100).round();
    final columns = width < 360
        ? 1
        : width >= AppBreakpoints.medium
        ? 4
        : 2;
    final gap = AppSpacing.sm;
    final itemWidth = (width - gap * (columns - 1)) / columns;

    final items = [
      _DashboardMetric(
        icon: Icons.assignment_outlined,
        label: '待办作业',
        value: '$_pendingCount',
        caption: _pendingCount == 0 ? '全部完成' : '项待处理',
        foreground: _pendingCount == 0 ? colors.success : colors.primary,
        background: _pendingCount == 0
            ? colors.successContainer
            : colors.primaryContainer,
      ),
      _DashboardMetric(
        icon: Icons.edit_note_rounded,
        label: '今日练习',
        value: '$_todayTotal',
        caption: '题已作答',
        foreground: colors.primary,
        background: colors.primaryContainer,
      ),
      _DashboardMetric(
        icon: Icons.track_changes_rounded,
        label: '今日正确率',
        value: '$accuracy%',
        caption: _todayTotal == 0 ? '完成练习后生成' : '$_todayCorrect 题正确',
        foreground: accuracy >= 80 ? colors.success : colors.recommendation,
        background: accuracy >= 80
            ? colors.successContainer
            : colors.recommendationContainer,
      ),
      _DashboardMetric(
        icon: Icons.workspace_premium_outlined,
        label: '当前等级',
        value: 'Lv.$_currentLevel',
        caption: '今日 +${formatAmount(_todayEarned)} 学习积分',
        foreground: colors.recommendation,
        background: colors.recommendationContainer,
      ),
    ];

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: items
          .map((item) => SizedBox(width: itemWidth, child: item))
          .toList(),
    );
  }

  Widget _buildLearningResources() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: '学习入口', subtitle: '按任务推进，或随时查阅课程讲义'),
          const SizedBox(height: AppSpacing.sm),
          _HomeActionTile(
            icon: Icons.assignment_outlined,
            title: '待办作业',
            subtitle: _pendingCount == 0
                ? '今天没有未完成作业'
                : '还有 $_pendingCount 项任务等待完成',
            onTap: () => RouterUtils.push(context, AppRoutes.homeworkList),
            trailing: _pendingCount > 0
                ? AppStatusBadge(
                    label: '$_pendingCount 项',
                    tone: AppStatusTone.warning,
                    compact: true,
                  )
                : const AppStatusBadge(
                    label: '已完成',
                    tone: AppStatusTone.success,
                    compact: true,
                  ),
          ),
          const Divider(height: AppSpacing.lg),
          _HomeActionTile(
            icon: Icons.menu_book_outlined,
            title: '课程讲义',
            subtitle: '浏览章节、知识点与配套内容',
            onTap: () => RouterUtils.push(context, AppRoutes.lectureCourses),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinCard() {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final todayReward = UserRepository.todayRewardText(_streakDays);
    final nextReward = UserRepository.nextRewardText(_streakDays);
    final progress = (_streakDays % 7) / 7.0;
    final tasks = UserRepository.computeTodayTasks(_todayTotal, _todayCorrect);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '连续学习',
            subtitle: '完成签到和每日任务，保持稳定节奏',
            action: AppButton(
              label: _checkedIn ? '已签到' : '签到',
              icon: _checkedIn
                  ? Icons.check_rounded
                  : Icons.local_fire_department,
              onPressed: _checkedIn ? null : _doCheckin,
              isLoading: _submitting,
              fullWidth: false,
              variant: _checkedIn
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.recommendationContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: colors.recommendation,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已连续学习 $_streakDays 天', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '今日奖励 +$todayReward · 明日可得 +$nextReward',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周第 ${(_streakDays % 7) + 1} 天',
                style: textTheme.bodySmall,
              ),
              Text('7 天阶段目标', style: textTheme.bodySmall),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Text('每日任务', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          ...tasks.map(
            (task) => _buildTaskItem(
              task.done,
              task.label,
              task.rewardText,
              inProgress: task.inProgress,
            ),
          ),
          const Divider(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Lv.$_currentLevel · 升级进度 $_levelProgress',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '今日学习积分 +${formatAmount(_todayEarned)}',
                style: textTheme.labelMedium?.copyWith(color: colors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    bool done,
    String label,
    String points, {
    bool inProgress = false,
  }) {
    final colors = context.colors;
    final icon = done
        ? Icons.check_circle_rounded
        : inProgress
        ? Icons.timelapse_rounded
        : Icons.radio_button_unchecked_rounded;
    final iconColor = done
        ? colors.success
        : inProgress
        ? colors.warning
        : colors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: done ? colors.textSecondary : colors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '+$points',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: done ? colors.textMuted : colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus() {
    final colors = context.colors;
    final online = ConnectivityMonitor().isOnline;
    late final IconData icon;
    late final String text;
    late final Color foreground;
    late final Color background;
    late final Color border;
    VoidCallback? onTap;

    if (!online) {
      icon = Icons.cloud_off_outlined;
      text = '当前离线，数据将在联网后自动同步';
      foreground = colors.onRecommendationContainer;
      background = colors.recommendationContainer;
      border = colors.recommendation;
    } else if (_syncPendingCount > 0) {
      icon = Icons.sync_problem_rounded;
      text = '$_syncPendingCount 条学习数据等待同步';
      foreground = colors.onWarningContainer;
      background = colors.warningContainer;
      border = colors.warning;
      onTap = () => RouterUtils.push(context, AppRoutes.syncQueue);
    } else {
      icon = Icons.cloud_done_outlined;
      text = '学习数据已全部同步';
      foreground = colors.onSuccessContainer;
      background = colors.successContainer;
      border = colors.success;
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: border.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(AppIcons.chevronRight, size: 20, color: foreground),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startQuickPractice() async {
    try {
      final dao = QuestionDao(DatabaseProvider());
      var question = await dao.getRandomByType(preferredType: 'choice');
      question ??= await dao.getRandomByType(preferredType: 'fill');
      question ??= await dao.getRandomByType();
      if (question == null || !mounted) {
        AppToast.show(context, icon: Icons.info_outline, message: '题库暂无数据');
        return;
      }
      await SolveRouteHelper.navigateTo(
        context,
        question.id,
        question.questionType,
      );
    } catch (error) {
      OperationLog.instance.error('index_page_quick_practice', error);
      AuditLogger.instance.error('IndexPage._startQuickPractice', error);
      if (!mounted) return;
      AppToast.show(
        context,
        icon: Icons.warning_amber_rounded,
        message: '加载失败，请稍后重试',
      );
    }
  }

  Widget _buildWelcomeHint() {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.infoContainer,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '第一次使用？从这里开始',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '快速练习、讲义、推荐和组卷构成主要学习路径。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '关闭提示',
                onPressed: () => setState(() => _showWelcomeHint = false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: '快速练习',
                tone: AppStatusTone.primary,
                compact: true,
              ),
              AppStatusBadge(
                label: '课程讲义',
                tone: AppStatusTone.info,
                compact: true,
              ),
              AppStatusBadge(
                label: '智能推荐',
                tone: AppStatusTone.recommendation,
                compact: true,
              ),
              AppStatusBadge(
                label: '自主组卷',
                tone: AppStatusTone.neutral,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(icon, size: 22, color: foreground),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: textTheme.titleLarge?.copyWith(color: foreground)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ] else
                Icon(AppIcons.chevronRight, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
