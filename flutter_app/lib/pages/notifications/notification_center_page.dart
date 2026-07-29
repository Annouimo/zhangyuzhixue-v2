import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/api/api_client.dart';
import '../../data/api/notification_api.dart';
import '../../domain/notification_repository.dart';
import '../router.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({
    super.key,
    this.repository,
    this.onUnreadChanged,
  });

  final NotificationRepository? repository;
  final VoidCallback? onUnreadChanged;

  @override
  State<NotificationCenterPage> createState() => NotificationCenterPageState();
}

class NotificationCenterPageState extends State<NotificationCenterPage> {
  late final NotificationRepository _repository =
      widget.repository ?? NotificationRepository(NotificationApi(ApiClient()));
  final ScrollController _scrollController = ScrollController();
  List<StudentNotification>? _items;
  String? _nextCursor;
  String? _error;
  bool _unreadOnly = false;
  bool _loadingMore = false;
  bool _markingAll = false;

  Future<void> refresh() => _refresh();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
      _nextCursor = null;
    });
    try {
      final page = await _repository.list(unreadOnly: _unreadOnly);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _nextCursor = page.nextCursor;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '通知加载失败，请稍后重试');
    }
  }

  Future<void> _refresh() async {
    try {
      final page = await _repository.list(unreadOnly: _unreadOnly);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _nextCursor = page.nextCursor;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '通知加载失败，请稍后重试');
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore || _items == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.list(
        unreadOnly: _unreadOnly,
        cursor: cursor,
      );
      if (!mounted) return;
      setState(() {
        _items = [...?_items, ...page.items];
        _nextCursor = page.nextCursor;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _items?.any((item) => item.isUnread) != true) return;
    setState(() => _markingAll = true);
    try {
      await _repository.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _unreadOnly
            ? []
            : _items!.map((item) => item.asRead()).toList(growable: false);
      });
      widget.onUnreadChanged?.call();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(StudentNotification item) async {
    if (item.isUnread) {
      try {
        await _repository.markRead(item.id);
        if (mounted) {
          setState(() {
            _items = _unreadOnly
                ? _items!.where((entry) => entry.id != item.id).toList()
                : _items!
                      .map(
                        (entry) => entry.id == item.id ? entry.asRead() : entry,
                      )
                      .toList();
          });
          widget.onUnreadChanged?.call();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    await _performAction(item);
  }

  Future<void> _performAction(StudentNotification item) async {
    if (item.actionType == 'data_update') {
      await RouterUtils.push(context, AppRoutes.syncQueue);
      return;
    }
    if (item.actionType != 'route') return;
    final id = item.payload['id'] as int?;
    final location = switch (item.actionTarget) {
      'contribution_detail' when id != null =>
        '${AppRoutes.contributionDetail}?id=$id',
      'contribution_edit' when id != null =>
        '${AppRoutes.contributionEdit}?id=$id',
      'sync_queue' => AppRoutes.syncQueue,
      'settings_account' => AppRoutes.settings,
      _ => null,
    };
    if (location != null) await RouterUtils.push(context, location);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('通知'),
      actions: [
        TextButton(
          onPressed: _markingAll ? null : _markAllRead,
          child: const Text('全部已读'),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('全部')),
              ButtonSegment(value: true, label: Text('未读')),
            ],
            selected: {_unreadOnly},
            onSelectionChanged: (selection) {
              final value = selection.first;
              if (value == _unreadOnly) return;
              setState(() => _unreadOnly = value);
              _load();
            },
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    ),
  );

  Widget _buildBody() {
    if (_items == null && _error == null) {
      return const LoadingIndicator(message: '正在加载通知…');
    }
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_items!.isEmpty) {
      return AppStatePanel(
        title: _unreadOnly ? '没有未读通知' : '暂无通知',
        message: _unreadOnly ? '新通知会显示在这里。' : '重要进展和系统消息会显示在这里。',
        tone: AppStateTone.empty,
        icon: Icons.notifications_none_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: _items!.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == _items!.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _NotificationTile(item: _items![index], onTap: _open);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final StudentNotification item;
  final ValueChanged<StudentNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.category) {
      'contribution' => Icons.rate_review_outlined,
      'sync' => Icons.sync_problem_rounded,
      'account' => Icons.shield_outlined,
      'achievement' => Icons.emoji_events_outlined,
      'points' => Icons.toll_outlined,
      _ => Icons.campaign_outlined,
    };
    return AppCard(
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: item.isUnread
                    ? context.colors.primary
                    : context.colors.textMuted,
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
                            item.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: item.isUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                        if (item.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (item.content.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _timeLabel(item.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.month}月${local.day}日';
  }
}
