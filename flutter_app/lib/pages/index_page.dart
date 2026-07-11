import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../widgets/shared/loading_indicator.dart';
import '../widgets/shared/app_toast.dart';

/// 首页（匹配 HTML 原型 index.html — 看板式布局）
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  bool _loading = true;
  int _pendingCount = 0;
  int _streakDays = 0;
  bool _checkedIn = false;

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
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getInt('pending_homework_count') ?? 0;
      final streak = prefs.getInt('checkin_streak') ?? 0;
      final checkedIn = prefs.getBool('checked_in_today') ?? false;
      if (!mounted) return;
      setState(() {
        _pendingCount = pending;
        _streakDays = streak;
        _checkedIn = checkedIn;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _doCheckin() async {
    if (_checkedIn) {
      AppToast.show(context, icon: 'ℹ️', message: '今天已签到');
      return;
    }
    // TODO: 接入实际签到 API / 本地签到逻辑
    final prefs = await SharedPreferences.getInstance();
    final newStreak = (_streakDays % 7) + 1; // 循环 7 天周期
    await prefs.setInt('checkin_streak', newStreak);
    await prefs.setBool('checked_in_today', true);
    if (!mounted) return;
    setState(() {
      _streakDays = newStreak;
      _checkedIn = true;
    });
    AppToast.show(context,
      icon: '🔥', message: '签到成功！连续第 $_streakDays 天',
      backgroundColor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: _loading
          ? const LoadingIndicator()
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
      onTap: () => context.push('/homework/list'),
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
            const Text('📝', style: TextStyle(fontSize: 20)),
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
      onTap: () => context.push('/lecture/courses'),
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
            const Text('📖', style: TextStyle(fontSize: 20)),
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
    final todayReward = _calcTodayReward();
    final nextReward = _calcNextReward();
    final progress = (_streakDays % 7) / 7.0;
    final dayInWeek = (_streakDays % 7) + 1;

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
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                '已连续签到 $_streakDays 天',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                height: 32,
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
              Text('+$nextReward 🎉',
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
              backgroundColor: const Color(0xFFE5E7EB),
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
          _buildTaskItem(dayInWeek >= 1, '开张有礼（完成第1题）', '0.5'),
          _buildTaskItem(dayInWeek >= 2, '小试牛刀（完成5题）', '1.0'),
          _buildTaskItem(dayInWeek >= 3, '精益求精（正确率≥60%）', '1.0', inProgress: dayInWeek == 2),
          _buildTaskItem(dayInWeek >= 4, '更进一步（完成15题）', '2.0', inProgress: dayInWeek == 3),
          // 等级进度行
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🏅 Lv.5 → 升级还需 7.8',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('今日学习积分 +${_streakDays * 0.5}',
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

  double _calcTodayReward() => 0.5 + (_streakDays % 7) * 0.3;
  double _calcNextReward() => 0.5 + ((_streakDays + 1) % 7) * 0.3;
}
