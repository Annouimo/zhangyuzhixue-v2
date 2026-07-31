import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_state_panel.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/filter_panel_components.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import '../../widgets/shared/format_utils.dart';

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
  _PointsFilter _filter = _PointsFilter.all;

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(title: const Text('积分明细')),
      body: _loading
          ? const LoadingIndicator(message: '正在加载积分记录…')
          : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final records = _records ?? [];
    final visibleRecords = records
        .where((record) => record.change != 0 && _matchesFilter(record))
        .toList();
    const filterLabels = <_PointsFilter, String>{
      _PointsFilter.all: '全部',
      _PointsFilter.earned: '获得',
      _PointsFilter.spent: '消耗',
      _PointsFilter.adjusted: '调整',
    };
    return AppContentContainer(
      maxWidth: AppContentWidth.dashboard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          _Summary(
            earned: _earned,
            bonus: _bonus,
            spent: _spent,
            available: _available,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: '积分明细', compact: true),
          const SizedBox(height: AppSpacing.sm),
          FilterChoiceGroup(
            label: '',
            options: filterLabels.values.toList(),
            selected: {filterLabels[_filter]!},
            onChanged: (label, _) {
              final value = filterLabels.entries
                  .firstWhere((entry) => entry.value == label)
                  .key;
              setState(() => _filter = value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (records.isEmpty)
            const AppStatePanel(
              title: '暂无积分记录',
              message: '完成一次练习或签到后，积分变化会显示在这里。',
              tone: AppStateTone.empty,
              icon: Icons.receipt_long_outlined,
            )
          else if (visibleRecords.isEmpty)
            const AppStatePanel(
              title: '暂无此类积分记录',
              message: '切换其他类型查看积分流水。',
              tone: AppStateTone.empty,
              icon: Icons.receipt_long_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return _PointsLedger(
                  records: visibleRecords,
                  wide: constraints.maxWidth >= AppBreakpoints.medium,
                );
              },
            ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  bool _matchesFilter(PointsRecord record) => switch (_filter) {
    _PointsFilter.all => true,
    _PointsFilter.earned =>
      record.change > 0 && record.source != 'ADMIN_ADJUST',
    _PointsFilter.spent => record.change < 0 && record.source != 'ADMIN_ADJUST',
    _PointsFilter.adjusted => record.source == 'ADMIN_ADJUST',
  };
}

enum _PointsFilter { all, earned, spent, adjusted }

class _Summary extends StatelessWidget {
  const _Summary({
    required this.earned,
    required this.bonus,
    required this.spent,
    required this.available,
  });
  final double earned, bonus, spent, available;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('可用积分', style: Theme.of(context).textTheme.labelLarge),
      Text(
        formatAmount(available),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '累计获得 ${formatAmount(earned + bonus)} · 已消耗 ${formatAmount(spent)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _PointsLedger extends StatelessWidget {
  const _PointsLedger({required this.records, required this.wide});

  final List<PointsRecord> records;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PointsRecord>>{};
    for (final record in records) {
      groups.putIfAbsent(_dateGroup(record.time), () => []).add(record);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide) const _PointsTableHeader(),
        for (final entry in groups.entries) ...[
          _PointsGroupTitle(label: entry.key),
          for (var index = 0; index < entry.value.length; index++) ...[
            if (wide)
              _PointsTableRow(record: entry.value[index])
            else
              _PointsRecordRow(record: entry.value[index]),
            if (index < entry.value.length - 1)
              Divider(height: 1, color: context.colors.divider),
          ],
        ],
      ],
    );
  }
}

class _PointsGroupTitle extends StatelessWidget {
  const _PointsGroupTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _PointsTableHeader extends StatelessWidget {
  const _PointsTableHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text('事由', style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          flex: 2,
          child: Text('时间', style: Theme.of(context).textTheme.labelMedium),
        ),
        SizedBox(
          width: 88,
          child: Text(
            '变动',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            '余额',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    ),
  );
}

class _PointsTableRow extends StatelessWidget {
  const _PointsTableRow({required this.record});

  final PointsRecord record;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showPointsDetail(context, record),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(_reason(record))),
            Expanded(
              flex: 2,
              child: Text(
                _displayTime(record.time),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SizedBox(
              width: 88,
              child: Text(
                _delta(record.change),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _changeColor(context, record.change),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                formatAmount(record.available),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PointsRecordRow extends StatelessWidget {
  const _PointsRecordRow({required this.record});

  final PointsRecord record;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showPointsDetail(context, record),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(_reason(record))),
                Text(
                  _delta(record.change),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _changeColor(context, record.change),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${_displayTime(record.time)} · 余额 ${formatAmount(record.available)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _delta(double value) =>
    value > 0 ? '+${formatAmount(value)}' : formatAmount(value);

Color _changeColor(BuildContext context, double value) => value > 0
    ? context.colors.success
    : value < 0
    ? context.colors.error
    : context.colors.textMuted;

String _reason(PointsRecord record) {
  final description = record.description?.trim() ?? '';
  if (record.source == 'ADMIN_ADJUST' && description.isNotEmpty) {
    return '${record.type}：$description';
  }
  return record.type;
}

String _displayTime(String value) {
  final parsed = DateTime.tryParse(value);
  final date = parsed?.isUtc == true ? parsed!.toLocal() : parsed;
  if (date == null) return value;
  return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _dateGroup(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '较早';
  final date = parsed.isUtc ? parsed.toLocal() : parsed;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return '今天';
  if (difference == 1) return '昨天';
  return '较早';
}

Future<void> _showPointsDetail(BuildContext context, PointsRecord record) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_reason(record)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间：${_displayTime(record.time)}'),
            Text('本次变动：${_delta(record.change)}'),
            const SizedBox(height: AppSpacing.sm),
            Text('学习积分：${formatAmount(record.earned)}'),
            Text('赠送积分：${formatAmount(record.bonus)}'),
            Text('累计消耗：${formatAmount(record.spent)}'),
            Text('调整后余额：${formatAmount(record.available)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
