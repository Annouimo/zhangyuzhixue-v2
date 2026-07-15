import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/daos/achievement_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/achievement_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../data/debug/audit_logger.dart';

/// 成就页 — 匹配 HTML 原型 achievement.html
class AchievementPage extends StatefulWidget {
  final AchievementRepository? achievementRepository;
  const AchievementPage({super.key, this.achievementRepository});

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
    _repo = widget.achievementRepository ?? AchievementRepository(AchievementDao(DatabaseProvider()), QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summary = await _repo.getSummary();   // 实时推算，不再依赖缓存表
      final cats = await _repo.getCategories();
      if (!mounted) return;
      setState(() { _summary = summary; _categories = cats; _loading = false; });
      AuditLogger.instance.page('AchievementPage', {'unlocked': summary.unlockedCount, 'total': summary.totalCount});
    } catch (e) { AuditLogger.instance.error('AchievementPage._load', e); if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('成就')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载成就…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    final cats = _categories ?? [];
    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: [
        _buildSummary(),
        const SizedBox(height: 16),
        ...cats.map((cat) => _buildCategory(cat)),
      ],
    );
  }

  Widget _buildSummary() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            '${s.unlockedCount} / ${s.totalCount}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          const Text('已解锁成就',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCategory(AchievementCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(cat.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ...cat.list.map((a) => _buildAchievementItem(a)),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(AchievementItem a) {
    Color statusBg;
    Color statusFg;
    String statusLabel;
    switch (a.status) {
      case 'unlocked':
        statusBg = AppColors.statusCompletedBg;
        statusFg = AppColors.success;
        statusLabel = '已解锁';
        break;
      case 'in_progress':
        statusBg = AppColors.statusInProgressBg;
        statusFg = AppColors.warning;
        statusLabel = '进行中';
        break;
      default:
        statusBg = AppColors.statusPendingBg;
        statusFg = AppColors.textSecondary;
        statusLabel = '未解锁';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(a.iconEmoji, style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(a.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (a.status == 'unlocked' && a.unlockedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text('${a.unlockedAt} 解锁',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                if (a.status == 'in_progress')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60, height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (a.progressPercent / 100).clamp(0.0, 1.0),
                              backgroundColor: AppColors.border,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.isAccuracyRate
                            ? '${a.progress}% / ${a.threshold}%'
                            : '${a.progress}/${a.threshold}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusFg)),
          ),
        ],
      ),
    );
  }
}
