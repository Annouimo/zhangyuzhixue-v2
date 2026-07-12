import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../data/debug/audit_logger.dart';

/// 积分流水页 — 匹配 HTML 原型 points.html
class PointsPage extends StatefulWidget {
  final UserRepository? userRepository;
  const PointsPage({super.key, this.userRepository});

  @override State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  late final UserRepository _repo;
  List<PointsRecord>? _records;
  double _earned = 0, _bonus = 0, _spent = 0, _available = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb));
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getPointsHistory();
      final earned = await _repo.earnedPoints();
      final bonus = await _repo.bonusPoints();
      final spent = await _repo.spentPoints();
      final available = await _repo.availablePoints();
      if (!mounted) return;
      setState(() { _records = list; _earned = earned; _bonus = bonus; _spent = spent; _available = available; _loading = false; });
      AuditLogger.instance.page('PointsPage', {'recordCount': _records?.length});
    } catch (e) {
      AuditLogger.instance.error('PointsPage._load', e);
      debugPrint('_load error: $e');
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('积分流水')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ErrorPlaceholder(message: _error!, onRetry: _load)
            : ListView(
              padding: const EdgeInsets.all(AppSizes.baseSpacing),
              children: [
                _buildSummary(),
                const SizedBox(height: 16),
                ..._buildTableRows(),
              ],
            ),
  );

  Widget _buildSummary() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  List<Widget> _buildTableRows() {
    final list = _records ?? [];
    if (list.isEmpty) {
      return [const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('暂无流水记录', style: TextStyle(color: AppColors.textSecondary)),
      ))];
    }
    return list.map((r) {
      final isPositive = r.change >= 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(r.type, style: const TextStyle(fontSize: 13))),
            Expanded(flex: 2, child: Text(r.time.length >= 10 ? r.time.substring(0, 10) : r.time,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text('${isPositive ? '+' : ''}${r.change.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isPositive ? AppColors.success : AppColors.error))),
            SizedBox(width: 48, child: Text(r.earned.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text(r.bonus.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text(r.spent.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text(r.available.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          ],
        ),
      );
    }).toList();
  }
}
