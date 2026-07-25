import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_state_panel.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import '../../widgets/shared/format_utils.dart';
import '../../widgets/shared/point_summary_card.dart';

/// 积分汇总与流水记录。
class PointsPage extends StatefulWidget {
  const PointsPage({super.key, this.userRepository});

  final UserRepository? userRepository;

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  late final UserRepository _repo;
  List<PointsRecord>? _records;
  double _earned = 0;
  double _bonus = 0;
  double _spent = 0;
  double _available = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.userRepository ??
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
      final list = await _repo.getPointsHistory();
      if (!mounted) return;
      final summary = list.isNotEmpty ? list.first : null;
      setState(() {
        _records = list;
        _earned = summary?.earned ?? 0;
        _bonus = summary?.bonus ?? 0;
        _spent = summary?.spent ?? 0;
        _available = summary?.available ?? 0;
        _loading = false;
      });
      AuditLogger.instance.page('PointsPage', {'recordCount': list.length});
    } catch (error) {
      OperationLog.instance.error('points_page_load', error);
      AuditLogger.instance.error('PointsPage._load', error);
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
      appBar: AppBar(title: const Text('积分流水')),
      body: _loading
          ? const LoadingIndicator(message: '正在加载积分记录…')
          : _error != null
              ? ErrorPlaceholder(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final records = _records ?? [];
    return AppContentContainer(
      maxWidth: AppContentWidth.dashboard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          PointSummaryCard(
            earned: _earned,
            bonus: _bonus,
            spent: _spent,
            available: _available,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(
            title: '积分明细',
            subtitle: '学习、任务奖励与组卷消耗都会记录在这里。',
          ),
          const SizedBox(height: AppSpacing.md),
          if (records.isEmpty)
            const AppStatePanel(
              title: '暂无积分记录',
              message: '完成一次练习或签到后，积分变化会显示在这里。',
              tone: AppStateTone.empty,
              icon: Icons.receipt_long_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= AppBreakpoints.medium) {
                  return _PointsTable(records: records);
                }
                return Column(
                  children: records
                      .map((record) => _PointsRecordCard(record: record))
                      .toList(),
                );
              },
            ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: context.colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '做题会增加学习积分；签到、任务和评价会增加赠送积分；组卷会消耗可用积分。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _PointsRecordCard extends StatelessWidget {
  const _PointsRecordCard({required this.record});

  final PointsRecord record;

  @override
  Widget build(BuildContext context) {
    final positive = record.change >= 0;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(record.type, style: Theme.of(context).textTheme.titleMedium),
              ),
              AppStatusBadge(
                label: '${positive ? '+' : ''}${formatAmount(record.change)}',
                tone: positive ? AppStatusTone.success : AppStatusTone.error,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(record.time, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _ValueLabel(label: '学习', value: record.earned),
              _ValueLabel(label: '赠送', value: record.bonus),
              _ValueLabel(label: '消耗', value: record.spent),
              _ValueLabel(label: '可用', value: record.available, emphasize: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: Theme.of(context).textTheme.labelSmall,
        children: [
          TextSpan(
            text: formatAmount(value),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: emphasize ? context.colors.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _PointsTable extends StatelessWidget {
  const _PointsTable({required this.records});

  final List<PointsRecord> records;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Text('时间')),
            DataColumn(label: Text('类型')),
            DataColumn(label: Text('变动'), numeric: true),
            DataColumn(label: Text('学习'), numeric: true),
            DataColumn(label: Text('赠送'), numeric: true),
            DataColumn(label: Text('消耗'), numeric: true),
            DataColumn(label: Text('可用'), numeric: true),
          ],
          rows: records.map((record) {
            final positive = record.change >= 0;
            return DataRow(
              cells: [
                DataCell(Text(record.time.length >= 10
                    ? record.time.substring(0, 10)
                    : record.time)),
                DataCell(Text(record.type)),
                DataCell(Text(
                  '${positive ? '+' : ''}${formatAmount(record.change)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: positive
                        ? context.colors.success
                        : context.colors.error,
                  ),
                )),
                DataCell(Text(formatAmount(record.earned))),
                DataCell(Text(formatAmount(record.bonus))),
                DataCell(Text(formatAmount(record.spent))),
                DataCell(Text(
                  formatAmount(record.available),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
