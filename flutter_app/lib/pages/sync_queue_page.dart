import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/app_state_panel.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_section.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_page_hint.dart';
import 'package:shared/widgets/app_toast.dart';
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
  const SyncQueuePage({super.key, this.syncRepository});

  @override
  State<SyncQueuePage> createState() => _SyncQueuePageState();
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
    _repo =
        widget.syncRepository ??
        SyncRepository(SyncQueueDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.getQueue();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      AuditLogger.instance.page('SyncQueuePage', {'pending': _items?.length});
    } catch (e) {
      OperationLog.instance.error('sync_queue_page_load', e);
      AuditLogger.instance.error('SyncQueuePage._load', e);
      OperationLog.instance.error('SyncQueuePage._load', e);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _onRetryAll() async {
    setState(() => _retrying = true);
    try {
      await _repo.retryAll();
      // 重试后刷新列表
      await _load();
      if (!mounted) return;
      AppToast.success(context, '已重置失败项，将在下次同步时重试');
    } catch (_) {}
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '等待同步';
      case 'inProgress':
        return '同步中…';
      case 'failed':
        return '同步失败';
      case 'permanentFailure':
        return '已放弃';
      default:
        return status;
    }
  }

  AppStatusTone _statusTone(String status) {
    return switch (status) {
      'pending' => AppStatusTone.neutral,
      'inProgress' => AppStatusTone.warning,
      'failed' => AppStatusTone.error,
      'permanentFailure' => AppStatusTone.error,
      _ => AppStatusTone.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final retryableCount =
        _items
            ?.where(
              (item) =>
                  item.status == 'pending' ||
                  item.status == 'failed' ||
                  item.status == 'permanentFailure',
            )
            .length ??
        0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步状态'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () => safePop(context),
        ),
      ),
      body: _buildBody(retryableCount),
    );
  }

  Widget _buildBody(int retryableCount) {
    if (_loading) {
      return const LoadingIndicator(message: '正在读取本地同步队列…');
    }
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }

    final items = _items ?? [];
    if (items.isEmpty) {
      return const AppStatePanel(
        title: '全部数据已同步',
        message: '你的学习记录、答题进度和个人设置已经安全保存。',
        tone: AppStateTone.success,
      );
    }

    return AppContentContainer(
      maxWidth: AppContentWidth.standard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          AppSectionHeader(
            title: '同步队列',
            action: AppButton(
              label: '全部重试',
              icon: Icons.refresh,
              onPressed: retryableCount == 0 || _retrying ? null : _onRetryAll,
              isLoading: _retrying,
              variant: AppButtonVariant.secondary,
              expanded: false,
            ),
          ),
          AppPageHint(message: '$retryableCount 项等待处理'),
          const SizedBox(height: AppSpacing.md),
          ...items.map((item) {
            final failed =
                item.status == 'failed' || item.status == 'permanentFailure';
            return AppSection(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: failed
                          ? context.colors.errorContainer
                          : context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Icon(
                      item.icon,
                      color: failed
                          ? context.colors.onErrorContainer
                          : context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.entityTypeName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            AppStatusBadge(
                              label: _statusLabel(item.status),
                              tone: _statusTone(item.status),
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.errorMessage ?? item.timeAgo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: failed
                                    ? context.colors.error
                                    : context.colors.textSecondary,
                              ),
                        ),
                        if (item.retryCount > 0) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '已重试 ${item.retryCount} 次',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
