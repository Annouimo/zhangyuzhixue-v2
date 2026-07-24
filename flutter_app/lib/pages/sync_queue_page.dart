import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../data/daos/sync_queue_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/sync_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'router.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 同步队列状态页
class SyncQueuePage extends StatefulWidget {
  final SyncRepository? syncRepository;
  SyncQueuePage({super.key, this.syncRepository});

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
    _repo = widget.syncRepository ?? SyncRepository(SyncQueueDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _repo.getQueue();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
      AuditLogger.instance.page('SyncQueuePage', {'pending': _items?.length});
    } catch (e) { OperationLog.instance.error('sync_queue_page_load', e); 
      AuditLogger.instance.error('SyncQueuePage._load', e);
      OperationLog.instance.error('SyncQueuePage._load', e);
      if (!mounted) return;
      setState(() { _error = '加载失败，请稍后重试'; _loading = false; });
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
        SnackBar(content: Text('已重置失败项，将在下次同步时重试'), behavior: SnackBarBehavior.floating),
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
      case 'pending': return context.colors.textSecondary;
      case 'inProgress': return context.colors.warning;
      case 'failed': return context.colors.error;
      case 'permanentFailure': return context.colors.textMuted;
      default: return context.colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('同步状态'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: '返回',
        onPressed: () => safePop(context),
      ),
      actions: [
        if (_items != null && _items!.any((i) => i.status == 'pending' || i.status == 'failed'))
          IconButton(
            icon: _retrying
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.refresh),
            tooltip: '全部重试',
            onPressed: _retrying ? null : _onRetryAll,
          ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return LoadingIndicator(message: '加载同步队列…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);

    final items = _items ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('✅', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('全部已同步', style: TextStyle(fontSize: 16, color: context.colors.textSecondary)),
        ]),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(AppSizes.baseSpacing),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1),
      itemBuilder: (_, i) {
        final item = items[i];
        final isFailed = item.status == 'failed';
        return ListTile(
          leading: Icon(item.icon, size: 24, color: context.colors.primary),
          title: Text(item.entityTypeName, style: TextStyle(fontSize: 15)),
          subtitle: item.errorMessage != null
              ? Text(item.errorMessage!,
                  style: TextStyle(fontSize: 11, color: context.colors.error),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)
              : Text(item.timeAgo,
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 100),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_statusLabel(item.status),
                style: TextStyle(fontSize: 13, color: _statusColor(item.status))),
              if (isFailed) ...[
                SizedBox(width: 4),
                Text('(${item.retryCount})', style: TextStyle(fontSize: 11, color: context.colors.error)),
              ],
            ]),
          ),
        );
      },
    );
  }
}


