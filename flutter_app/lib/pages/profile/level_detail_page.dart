import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_section.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/prefs/app_prefs.dart';
import '../../domain/user_repository.dart';
import '../../widgets/shared/point_summary_card.dart';

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
        if (mounted) setState(() => _percentile = percentile);
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
                  AppSectionHeader(
                    title: 'Lv.$_level',
                    subtitle: '超过 $_percentile% 的用户',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PointSummaryCard(
                    earned: _earned,
                    bonus: _bonus,
                    spent: _spent,
                    available: _available,
                    valueFontSize: 20,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSection(
                    title: '等级对照',
                    description: '当前等级会随累计学习积分自动更新。',
                    showDivider: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [..._levels.map(_buildLevelRow)],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelRow(LevelRow row) {
    final current = row.level == _level;
    final future = row.level > _level;
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: current ? colors.primaryContainer : colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: current ? colors.primaryBorder : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: current ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(
              'Lv.${row.level}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: current ? colors.onPrimary : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              row.range,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: future ? colors.textMuted : colors.textPrimary,
                fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (current)
            const AppStatusBadge(
              label: '当前',
              tone: AppStatusTone.primary,
              compact: true,
            )
          else if (future)
            Icon(Icons.lock_outline_rounded, size: 18, color: colors.textMuted)
          else
            Icon(Icons.check_circle_rounded, size: 18, color: colors.success),
        ],
      ),
    );
  }
}
