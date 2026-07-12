import 'package:flutter/material.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../data/debug/audit_logger.dart';

/// 等级详情页 — 匹配 HTML 原型 level_detail.html
class LevelDetailPage extends StatefulWidget {
  final UserRepository? userRepository;
  const LevelDetailPage({super.key, this.userRepository});

  @override State<LevelDetailPage> createState() => _LevelDetailPageState();
}

class _LevelDetailPageState extends State<LevelDetailPage> {
  late final UserRepository _repo;
  bool _loading = true;
  String? _error;
  int _level = 1;
  int _percentile = 0;
  double _earned = 0, _bonus = 0, _spent = 0, _available = 0;
  List<LevelRow> _levels = [];

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lv = await _repo.currentLevel();
      final pctl = await _repo.levelPercentile();
      final earned = await _repo.earnedPoints();
      final bonus = await _repo.bonusPoints();
      final spent = await _repo.spentPoints();
      final available = await _repo.availablePoints();
      final levels = await _repo.getLevels();
      if (!mounted) return;
      setState(() {
        _level = lv; _percentile = pctl;
        _earned = earned; _bonus = bonus; _spent = spent; _available = available;
        _levels = levels; _loading = false;
      });
      AuditLogger.instance.page('LevelDetailPage', {'level': _level, 'earned': _earned});
    } catch (e) {
      AuditLogger.instance.error('LevelDetailPage._load', e);
      debugPrint('_load error: $e');
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('等级进度')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ErrorPlaceholder(message: _error!, onRetry: _load)
            : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.baseSpacing),
              child: Column(children: [
                // 等级徽章
                _buildBadge(),
                const SizedBox(height: 4),
                // 超过百分比
                Text('超过 $_percentile% 的用户',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                // 4 积分概览
                _buildPointsSummary(),
                const SizedBox(height: 16),
                // 等级对照表
                _buildLevelTable(),
              ]),
            ),
  );

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏅', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 6),
          Text('Lv.$_level',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPointsSummary() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _pointItem('学习积分', _earned, AppColors.primary),
            _pointItem('赠送积分', _bonus, AppColors.warning),
            _pointItem('消耗积分', _spent, AppColors.error),
            _pointItem('可用积分', _available, AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _pointItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toStringAsFixed(1),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLevelTable() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('等级对照',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            const Text('等级依据学习积分计算',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FixedColumnWidth(50), 1: FlexColumnWidth()},
              children: _levels.map((r) {
                final isCurrent = r.level == _level;
                return TableRow(
                  decoration: isCurrent
                      ? const BoxDecoration(color: AppColors.primaryLight)
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text('Lv.${r.level}',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13,
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                        )),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(r.range,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                        )),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
