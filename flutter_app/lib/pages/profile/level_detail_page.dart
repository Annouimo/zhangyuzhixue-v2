import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/prefs/app_prefs.dart';
import '../../domain/user_repository.dart';
import '../../widgets/shared/format_utils.dart';

/// 等级成长详情。
class LevelDetailPage extends StatefulWidget {
  const LevelDetailPage({super.key, this.userRepository});

  final UserRepository? userRepository;

  @override
  State<LevelDetailPage> createState() => _LevelDetailPageState();
}

class _LevelDetailPageState extends State<LevelDetailPage> {
  late final UserRepository _repo;
  bool _loading = true;
  String? _error;
  int _level = 1;
  late int _percentile;
  double _earned = 0;
  double _bonus = 0;
  double _spent = 0;
  double _available = 0;
  List<LevelRow> _levels = [];

  @override
  void initState() {
    super.initState();
    _percentile = AppPrefs().levelPercentile;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final level = await _repo.currentLevel();
      final summary = await _repo.getPointsSummary();
      final levels = await _repo.getLevels();
      if (!mounted) return;
      setState(() {
        _level = level;
        _earned = summary.earned;
        _bonus = summary.bonus;
        _spent = summary.spent;
        _available = summary.available;
        _levels = levels;
        _loading = false;
      });
      AuditLogger.instance.page('LevelDetailPage', {
        'level': _level,
        'earned': _earned,
      });
      try {
        final percentile = await _repo.levelPercentile();
        if (mounted) setState(() => _percentile = percentile.clamp(0, 100));
      } catch (_) {}
    } catch (error) {
      OperationLog.instance.error('level_detail_page_load', error);
      AuditLogger.instance.error('LevelDetailPage._load', error);
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
      appBar: AppBar(title: const Text('等级详情')),
      body: _loading
          ? const LoadingIndicator(message: '正在计算成长等级…')
          : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : AppContentContainer(
              maxWidth: AppContentWidth.standard,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  _buildProgressSummary(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('积分概览', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPointsSummary(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('等级对照', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ..._levels.map(_buildLevelRow),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressSummary() {
    final currentMin = _currentMin;
    final nextMin = _nextMin;
    final progress = currentMin == null || nextMin == null
        ? 0.0
        : ((_earned - currentMin) / (nextMin - currentMin)).clamp(0.0, 1.0);
    final remaining = nextMin == null
        ? 0.0
        : (nextMin - _earned).clamp(0.0, double.infinity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lv.$_level', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          nextMin == null
              ? '学习积分 ${formatAmount(_earned)}'
              : '学习积分 ${formatAmount(_earned)} / ${formatAmount(nextMin)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(value: progress, minHeight: 8),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (nextMin != null)
          Text('距离 Lv.${_level + 1} 还差 ${formatAmount(remaining)} 学习积分'),
        if (_percentile > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('超过 $_percentile% 的用户'),
        ],
      ],
    );
  }

  Widget _buildPointsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('可用积分', style: Theme.of(context).textTheme.labelLarge),
        Text(
          formatAmount(_available),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '学习获得 ${formatAmount(_earned)} · 赠送 ${formatAmount(_bonus)} · 已消耗 ${formatAmount(_spent)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '赠送积分和可用积分不影响等级。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  double? get _currentMin => _levels
      .where((row) => row.level == _level)
      .map((row) => double.tryParse(row.range.split(' ').first))
      .firstOrNull;

  double? get _nextMin {
    final next = _levels.where((row) => row.level > _level).toList();
    if (next.isEmpty) return null;
    return double.tryParse(next.first.range.split(' ').first);
  }

  Widget _buildLevelRow(LevelRow row) {
    final current = row.level == _level;
    final future = row.level > _level;
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: current ? colors.primaryContainer.withValues(alpha: 0.35) : null,
        border: Border(
          bottom: BorderSide(color: colors.divider),
          left: current
              ? BorderSide(color: colors.primary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(width: 56, child: Text('Lv.${row.level}')),
            Expanded(
              child: Text(
                row.range,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: future ? colors.textMuted : colors.textPrimary,
                  fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              current ? '当前' : future ? '未达成' : '已达成',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: current ? colors.primary : colors.textMuted,
                fontWeight: current ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
