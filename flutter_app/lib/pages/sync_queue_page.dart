import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../data/daos/sync_queue_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/sync_repository.dart';
import '../widgets/shared/loading_indicator.dart';
import '../widgets/shared/error_placeholder.dart';
import '../data/debug/audit_logger.dart';

/// 同步队列状态页
class SyncQueuePage extends StatefulWidget {
  final SyncRepository? syncRepository;
  const SyncQueuePage({super.key, this.syncRepository});

  @override State<SyncQueuePage> createState() => _SyncQueuePageState();
}

class _SyncQueuePageState extends State<SyncQueuePage> {
  late final SyncRepository _repo;
  List<SyncQueueItem>? _items;
  bool _loading = true;
  String? _error;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.syncRepository ?? SyncRepository(SyncQueueDao(DatabaseProvider().appDb));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _repo.getQueue();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
      AuditLogger.instance.page('SyncQueuePage', {'pending': _items?.length});
    } catch (e) {
      AuditLogger.instance.error('SyncQueuePage._load', e);
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _onRetryAll() async {
    setState(() => _retrying = true);
    try {
      await _repo.retryAll();
      // 重试后刷新列表
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重置失败项，将在下次同步时重试'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return '等待同步';
      case 'inProgress': return '同步中…';
      case 'failed': return '同步失败';
      case 'permanentFailure': return '已放弃';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.textSecondary;
      case 'inProgress': return AppColors.warning;
      case 'failed': return AppColors.error;
      case 'permanentFailure': return Colors.grey;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('同步状态'),
      actions: [
        if (_items != null && _items!.any((i) => i.status == 'failed'))
          IconButton(
            icon: _retrying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: '全部重试',
            onPressed: _retrying ? null : _onRetryAll,
          ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载同步队列…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);

    final items = _items ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('✅', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('全部已同步', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = items[i];
        final isFailed = item.status == 'failed';
        return ListTile(
          leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
          title: Text(item.entityTypeName, style: const TextStyle(fontSize: 15)),
          subtitle: Text(item.timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_statusLabel(item.status),
              style: TextStyle(fontSize: 13, color: _statusColor(item.status))),
            if (isFailed) ...[
              const SizedBox(width: 4),
              Text('(${item.retryCount})', style: const TextStyle(fontSize: 11, color: AppColors.error)),
            ],
          ]),
        );
      },
    );
  }
}
