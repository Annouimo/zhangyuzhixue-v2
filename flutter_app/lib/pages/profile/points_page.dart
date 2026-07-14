import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/shared/point_summary_card.dart';
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
      if (!mounted) return;
      // 从累积列表的最后一个元素获取汇总值（第一条是最新，累积到最终值）
      final summary = list.isNotEmpty
          ? list.first
          : null;
      setState(() {
        _records = list;
        _earned = summary?.earned ?? 0;
        _bonus = summary?.bonus ?? 0;
        _spent = summary?.spent ?? 0;
        _available = summary?.available ?? 0;
        _loading = false;
      });
      AuditLogger.instance.page('PointsPage', {'recordCount': _records?.length});
    } catch (e) {
      AuditLogger.instance.error('PointsPage._load', e);
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('积分流水')),
    body: _loading
        ? const LoadingIndicator()
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
    return PointSummaryCard(
      earned: _earned, bonus: _bonus, spent: _spent, available: _available,
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
    return [
      // 表头
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text('时间', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            Expanded(flex: 2, child: Text('类型', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text('变动', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text('学习', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text('赠送', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text('消耗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            SizedBox(width: 48, child: Text('可用', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          ],
        ),
      ),
      ...list.map((r) {
      final isPositive = r.change >= 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(r.time.length >= 10 ? r.time.substring(5, 10) : r.time,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            Expanded(flex: 2, child: Text(r.type, style: const TextStyle(fontSize: 13))),
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
    }),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: const Text('💡 类型说明：做题/签到/首题奖励/完成任务 → 学习积分增加；\n'
          '新人赠送 → 赠送积分增加；组卷消费 → 消耗增加+可用减少',
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ),
  ];
 }
}
