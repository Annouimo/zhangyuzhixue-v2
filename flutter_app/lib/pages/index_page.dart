import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column;
import 'router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/app_toast.dart';
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
    _repo = widget.userRepository ?? UserRepository(
      UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()),
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
      AuditLogger.instance.page('IndexPage', {'streakDays': _streakDays, 'pendingCount': _pendingCount, 'checkedIn': _checkedIn, 'level': _currentLevel});

      // 任务奖励检测（UI 已显示后再异步执行，不阻塞首屏）
      Future.microtask(() async {
        try {
          final tasks = UserRepository.computeTodayTasks(stats.total, stats.correct);
          for (var i = 0; i < tasks.length; i++) {
            if (tasks[i].done && prefs.getString('task_reward_${i}_date') != today) {
              await prefs.setString('task_reward_${i}_date', today);
              final now = DateTime.now().toIso8601String();
              final newId = await DatabaseProvider().appDb.into(DatabaseProvider().appDb.pointsTransactions).insert(
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
              AppToast.show(context, icon: Icons.task_alt, message: '${tasks[i].label} 完成！+${tasks[i].reward} 学习积分');
            }
          }
          // 全部任务完成提示
          if (mounted && tasks.every((t) => t.done)) {
            AppToast.show(context, icon: Icons.celebration, message: '🎉 全部每日任务已完成！今日额外 +1.0 学习积分');
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
            showLevelUpDialog(context, oldLevel: oldLevel, newLevel: _currentLevel, percentile: pctl);
          }
        } catch (_) {
          if (mounted) {
            showLevelUpDialog(context, oldLevel: oldLevel, newLevel: _currentLevel, percentile: 0);
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
      setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  Future<void> _doCheckin() async {
    if (_checkedIn) {
      AppToast.show(context, icon: Icons.info_outline, message: '今天已签到');
      return;
    }
    try {
      final result = await _repo.checkin();
      final streak = result['streak_days'] as int? ?? 0;
      final points = (result['points_earned'] as num?)?.toDouble() ?? 0.0;

      // 记录本地签到状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checked_in_today', true);

      // 写入本地登录日志，供下次启动推算连续天数
      final now = DateTime.now();
      final loginDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await AchievementDao(DatabaseProvider()).insertLoginLog(
        loginDate: loginDate,
        createdAt: now.toIso8601String(),
      );

      if (!mounted) return;
      // 在本地创建签到积分流水（服务端已创建，本地镜像）
      try {
        final now = DateTime.now();
        await DatabaseProvider().appDb.into(DatabaseProvider().appDb.pointsTransactions).insert(
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
      });
      OperationLog.instance.action('checkin', 'ok +$points pts, streak=$streak');
      AppToast.show(context,
        icon: Icons.local_fire_department, message: '签到成功！连续第 $streak 天 · +$points 学习积分',
        backgroundColor: AppColors.success,
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
              showLevelUpDialog(context, oldLevel: oldLevel, newLevel: newLevel, percentile: pctl);
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      OperationLog.instance.error('IndexPage._doCheckin', e); 
      AuditLogger.instance.error('IndexPage._doCheckin', e);
      if (!mounted) return;
      AppToast.show(context,
        icon: Icons.warning, message: '签到失败，请检查网络',
        backgroundColor: AppColors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorPlaceholder(message: _error!, onRetry: _load)
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 欢迎语卡片
                  _buildWelcomeCard(),
                  // 新手提示卡片（前 3 次）
                  if (_showWelcomeHint) _buildWelcomeHint(),
                  const SizedBox(height: 12),
                  // 快速练习
                  _buildQuickStart(),
                  // 待办作业
                  _buildPendingHomework(),
                  const SizedBox(height: 8),
                  // 讲义入口
                  _buildLectureEntry(),
                  const SizedBox(height: 12),
                  // 签到/任务卡片
                  _buildCheckinCard(),
                  const SizedBox(height: 8),
                  // 同步状态行
                  _buildSyncStatus(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            _welcomeText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '每天一句，保持节奏',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingHomework() {
    return InkWell(
      onTap: () => context.push(AppRoutes.homeworkList),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('待办作业',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$_pendingCount 项未完成',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureEntry() {
    return InkWell(
      onTap: () => context.push(AppRoutes.lectureCourses),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('讲义',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Text('浏览课程与讲义内容',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinCard() {
    final todayReward = UserRepository.todayRewardText(_streakDays);
    final nextReward = UserRepository.nextRewardText(_streakDays);
    final progress = (_streakDays % 7) / 7.0;
    final tasks = UserRepository.computeTodayTasks(_todayTotal, _todayCorrect);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: [
          // 签到行
          Row(
            children: [
              const Icon(Icons.local_fire_department, size: 20, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '已连续签到 $_streakDays 天',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                height: 32,
                width: 80,
                child: ElevatedButton(
                  onPressed: _doCheckin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(_checkedIn ? '已签到' : '签到'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 奖励行
          Row(
            children: [
              Text('今日奖励 ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('+$todayReward',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const Spacer(),
              Text('明日奖励 ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('+$nextReward',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 2),
          // 进度标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('第1天',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('第7天 🎯',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const Divider(height: 20),
          // 任务列表
          ...tasks.map((t) => _buildTaskItem(t.done, t.label, t.rewardText, inProgress: t.inProgress)),
          // 等级进度行
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🏅 Lv.$_currentLevel → 升级还需 ${_levelProgress.split('/').firstOrNull ?? ''}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('今日学习积分 +${formatAmount(_todayEarned)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(bool done, String label, String points, {bool inProgress = false}) {
    final icon = done
        ? const Icon(Icons.check_circle, size: 18, color: AppColors.success)
        : (inProgress
            ? const Icon(Icons.hourglass_empty, size: 18, color: AppColors.warning)
            : const Icon(Icons.circle_outlined, size: 18, color: AppColors.textSecondary));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: done ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text('+$points',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: done ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus() {
    final online = ConnectivityMonitor().isOnline;
    IconData icon;
    String text;
    VoidCallback? onTap;

    if (!online) {
      icon = Icons.cloud_off;
      text = '当前离线，数据将在联网后同步';
    } else if (_syncPendingCount > 0) {
      icon = Icons.sync_problem;
      text = '$_syncPendingCount 条数据待同步';
      onTap = () => context.push(AppRoutes.syncQueue);
    } else {
      icon = Icons.cloud_done;
      text = '全部已同步';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: !online
              ? Colors.orange.withValues(alpha: 0.08)
              : _syncPendingCount > 0
                  ? AppColors.warning.withValues(alpha: 0.08)
                  : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16,
              color: !online
                  ? Colors.orange
                  : _syncPendingCount > 0
                      ? AppColors.warning
                      : AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                style: TextStyle(
                  fontSize: 12,
                  color: !online
                      ? Colors.orange.shade700
                      : _syncPendingCount > 0
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }


  /// 快速练习 — 随机做一道题
  Widget _buildQuickStart() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: _startQuickPractice,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('🚀 快速练习 — 随机做一道题'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _startQuickPractice() async {
    try {
      final dao = QuestionDao(DatabaseProvider());
      var q = await dao.getRandomByType(preferredType: 'choice');
      q ??= await dao.getRandomByType(preferredType: 'fill');
      q ??= await dao.getRandomByType();
      if (q == null || !mounted) {
        AppToast.show(context, icon: Icons.info, message: '题库暂无数据');
        return;
      }
      await SolveRouteHelper.navigateTo(context, q.id, q.questionType);
    } catch (e) { OperationLog.instance.error('index_page_load', e); 
      AuditLogger.instance.error('IndexPage._startQuickPractice', e);
      if (!mounted) return;
      AppToast.show(context, icon: Icons.warning, message: '加载失败，请稍后重试');
    }
  }

  /// 新手提示引导卡片
  Widget _buildWelcomeHint() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('欢迎来到章鱼智学 🐙',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showWelcomeHint = false),
                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _hintItem(Icons.play_arrow, '🚀 快速练习 — 直接随机做一道题'),
          const SizedBox(height: 6),
          _hintItem(Icons.menu_book, '📖 讲义 — 浏览课程知识点'),
          const SizedBox(height: 6),
          _hintItem(Icons.auto_awesome, '🧠 推荐 — 智能推送适合你的题目'),
          const SizedBox(height: 6),
          _hintItem(Icons.description, '📝 组卷 — 自己组卷或使用他人试卷'),
        ],
      ),
    );
  }

  Widget _hintItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

