import 'package:flutter/material.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import '../../../widgets/shared/point_summary_card.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../../../data/prefs/app_prefs.dart';

/// 等级详情页 — 匹配 HTML 原型 level_detail.html
class LevelDetailPage extends StatefulWidget {
  final UserRepository? userRepository;
  LevelDetailPage({super.key, this.userRepository});

  @override State<LevelDetailPage> createState() => _LevelDetailPageState();
}

class _LevelDetailPageState extends State<LevelDetailPage> {
  late final UserRepository _repo;
  bool _loading = true;
  String? _error;
  int _level = 1;
  late int _percentile;
  double _earned = 0, _bonus = 0, _spent = 0, _available = 0;
  List<LevelRow> _levels = [];

  @override
  void initState() {
    super.initState();
    _percentile = AppPrefs().levelPercentile;
    _repo = widget.userRepository ?? UserRepository(UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lv = await _repo.currentLevel();
      final summary = await _repo.getPointsSummary();
      final levels = await _repo.getLevels();
      if (!mounted) return;
      setState(() {
        _level = lv;
        _earned = summary.earned; _bonus = summary.bonus;
        _spent = summary.spent; _available = summary.available;
        _levels = levels; _loading = false;
      });
      AuditLogger.instance.page('LevelDetailPage', {'level': _level, 'earned': _earned});
      // 百分位调 API，后台加载不阻塞首屏
      try {
        final pctl = await _repo.levelPercentile();
        if (mounted) setState(() => _percentile = pctl);
      } catch (_) {}
    } catch (e) { OperationLog.instance.error('level_detail_page_load', e); 
      AuditLogger.instance.error('LevelDetailPage._load', e);
      if (mounted) setState(() { _error = '加载失败，请稍后重试'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('等级详情')),
    body: _loading
        ? LoadingIndicator()
        : _error != null
            ? ErrorPlaceholder(message: _error!, onRetry: _load)
            : SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.baseSpacing),
              child: Column(children: [
                // 等级徽章
                _buildBadge(),
                SizedBox(height: 4),
                // 超过百分比
                Text('超过 $_percentile% 的用户',
                  style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                SizedBox(height: 16),
                // 4 积分概览
                _buildPointsSummary(),
                SizedBox(height: 16),
                // 等级对照表
                _buildLevelTable(),
              ]),
            ),
  );

  Widget _buildBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: Colors.white, size: 28),
          SizedBox(width: 6),
          Text('Lv.$_level',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPointsSummary() {
    return PointSummaryCard(
      earned: _earned, bonus: _bonus, spent: _spent, available: _available,
      valueFontSize: 20,
    );
  }

  Widget _buildLevelTable() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('等级对照',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text('等级依据学习积分计算',
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            SizedBox(height: 8),
            Table(
              columnWidths: {0: FixedColumnWidth(50), 1: FlexColumnWidth()},
              children: _levels.map((r) {
                final isCurrent = r.level == _level;
                return TableRow(
                  decoration: isCurrent
                      ? BoxDecoration(color: context.colors.primaryContainer)
                      : null,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text('Lv.${r.level}',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13,
                          color: r.level > _level
                              ? context.colors.textMuted
                              : (isCurrent ? context.colors.primary : context.colors.textPrimary),
                        )),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(r.range,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: r.level > _level
                              ? context.colors.textMuted
                              : (isCurrent ? context.colors.primary : context.colors.textSecondary),
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

