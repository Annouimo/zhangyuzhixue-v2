import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column;
import 'router.dart';
import '../app_theme.dart';
import '../widgets/shared/loading_indicator.dart';
import '../widgets/shared/error_placeholder.dart';
import '../widgets/shared/app_toast.dart';
import '../data/database/database_provider.dart';
import '../data/daos/achievement_dao.dart';
import '../data/api/api_client.dart';
import '../data/api/user_api.dart';
import '../data/daos/user_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/prefs/app_prefs.dart';
import '../domain/user_repository.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import '../data/debug/audit_logger.dart';
import '../data/database/app_database.dart' as app_db;

/// 首页（匹配 HTML 原型 index.html — 看板式布局）
class IndexPage extends StatefulWidget {
  final UserRepository? userRepository;
  const IndexPage({super.key, this.userRepository});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
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

  @override
  void initState() {
    super.initState();
    _welcomeText = _welcomeMessages[Random().nextInt(_welcomeMessages.length)];
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(
      UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb),
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
        final now = DateTime.now().toIso8601String();
        await AchievementDao(DatabaseProvider().appDb).insertLoginLog(
          loginDate: today,
          createdAt: now,
        );
      }

      final checkedIn = prefs.getBool('checked_in_today') ?? false;
      final pending = AppPrefs().pendingHomeworkCount;

      // 通过 AchievementDao 从登录日志推算连续签到天数
      final dao = AchievementDao(DatabaseProvider().appDb);
      final streak = await dao.getLoginStreak();

      // 等级进度
      final lvProgress = await _repo.levelProgress();
      final lv = await _repo.currentLevel();
      final todayEarned = await _repo.todayPoints();
      final stats = await _repo.getTodaySubmissionStats();

      // 任务奖励检测（每日仅发放一次）
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
          // 入同步队列
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
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingCount = pending;
        _streakDays = streak;
        _checkedIn = checkedIn;
        _levelProgress = lvProgress;
        _currentLevel = lv;
        _todayEarned = todayEarned;
        _todayTotal = stats.total;
        _todayCorrect = stats.correct;
        _loading = false;
      });
      AuditLogger.instance.page('IndexPage', {'streakDays': _streakDays, 'pendingCount': _pendingCount, 'checkedIn': _checkedIn, 'level': _currentLevel});
    } catch (e) {
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
      final points = result['points_earned'] as int? ?? 0;
      final msg = result['message'] as String? ?? '签到成功';

      // 记录本地签到状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('checked_in_today', true);

      // 写入本地登录日志，供下次启动推算连续天数
      final now = DateTime.now();
      final loginDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await AchievementDao(DatabaseProvider().appDb).insertLoginLog(
        loginDate: loginDate,
        createdAt: now.toIso8601String(),
      );

      if (!mounted) return;
      setState(() {
        _streakDays = streak;
        _checkedIn = true;
      });
      AppToast.show(context,
        icon: Icons.local_fire_department, message: '$msg · +$points 积分',
        backgroundColor: AppColors.success,
      );
    } catch (e) {
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
                  const SizedBox(height: 12),
                  // 待办作业
                  _buildPendingHomework(),
                  const SizedBox(height: 8),
                  // 讲义入口
                  _buildLectureEntry(),
                  const SizedBox(height: 12),
                  // 签到/任务卡片
                  _buildCheckinCard(),
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
              Text('今日学习积分 +${_todayEarned.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(bool done, String label, String points, {bool inProgress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(done ? '✅' : (inProgress ? '⏳' : '⬜'),
            style: const TextStyle(fontSize: 14)),
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

}
