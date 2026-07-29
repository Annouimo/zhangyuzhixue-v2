import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/api/api_client.dart';
import '../../data/api/contribution_api.dart';
import '../router.dart';

class ContributionListPage extends StatefulWidget {
  const ContributionListPage({super.key});

  @override
  State<ContributionListPage> createState() => _ContributionListPageState();
}

class _ContributionListPageState extends State<ContributionListPage>
    with WidgetsBindingObserver {
  late final ContributionApi _api = ContributionApi(ApiClient());
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_refreshing) _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _refreshing = true;
    });
    try {
      final items = await _api.list();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _error = '贡献记录加载失败');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openNew() async {
    final changed = await RouterUtils.push<bool>(
      context,
      '${AppRoutes.contributionNew}?mode=existing',
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('内容贡献'),
      actions: [
        IconButton(
          tooltip: '刷新贡献记录',
          onPressed: _refreshing ? null : _load,
          icon: _refreshing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: '编辑格式说明',
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () =>
              RouterUtils.push(context, AppRoutes.contributionHelp),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openNew,
      icon: const Icon(Icons.add_rounded),
      label: const Text('开始投稿'),
    ),
    body: _error != null
        ? ErrorPlaceholder(message: _error!, onRetry: _load)
        : _items == null
        ? const LoadingIndicator(message: '正在加载贡献记录')
        : AppContentContainer(
            maxWidth: AppContentWidth.dashboard,
            child: Column(
              children: [
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          '做题过程中，你可以在解题页面或题目详情中反馈题目错误、投稿新的解法。',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _items!.isEmpty
                      ? EmptyPlaceholder(
                          icon: Icons.rate_review_outlined,
                          message: '暂无贡献记录\n投稿新题后，处理进度会显示在这里。',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: _items!.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) =>
                                _buildItem(_items![index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
  );

  Widget _buildItem(Map<String, dynamic> item) {
    final status = item['status'] as String? ?? 'pending';
    final type = switch (item['contribution_type']) {
      'question_correction' => '题目纠错',
      'new_solution' => '解法投稿',
      _ => '新题投稿',
    };
    return Semantics(
      button: true,
      label: '查看$type详情',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          await RouterUtils.push<void>(
            context,
            '${AppRoutes.contributionDetail}?id=${item['id']}',
          );
          _load();
        },
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    type == '题目纠错'
                        ? Icons.report_outlined
                        : type == '解法投稿'
                        ? Icons.account_tree_outlined
                        : Icons.post_add_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      type,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  AppStatusBadge(
                    label: _statusLabel(status),
                    tone: _statusTone(status),
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              MdLatexBody(
                (item['summary'] as String?)?.trim().isNotEmpty == true
                    ? item['summary'] as String
                    : '暂无摘要',
              ),
              if ((item['review_note'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '审核意见：${item['review_note']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '第 ${item['revision_number']} 版',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (status == 'pending' || status == 'resubmitted')
                    TextButton.icon(
                      onPressed: () => _withdraw(item['id'] as int),
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('撤回'),
                    ),
                  if (status == 'needs_revision')
                    TextButton.icon(
                      onPressed: () async {
                        final changed = await RouterUtils.push<bool>(
                          context,
                          '${AppRoutes.contributionEdit}?id=${item['id']}',
                        );
                        if (changed == true) _load();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('修改'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _withdraw(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤回贡献'),
        content: const Text('撤回后不能继续修改这条记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('撤回'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.withdraw(id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('撤回失败，请稍后重试')));
      }
    }
  }

  String _statusLabel(String value) => switch (value) {
    'pending' => '待首次审核',
    'resubmitted' => '修改后待复审',
    'needs_revision' => '待修改',
    'processing' => '处理中',
    'approved_pending_release' => '已通过，待发布',
    'completed' => '已发布',
    'rejected' => '未采纳',
    'withdrawn' => '已撤回',
    _ => value,
  };

  AppStatusTone _statusTone(String value) => switch (value) {
    'completed' => AppStatusTone.success,
    'approved_pending_release' => AppStatusTone.info,
    'needs_revision' => AppStatusTone.warning,
    'rejected' || 'withdrawn' => AppStatusTone.neutral,
    'processing' => AppStatusTone.info,
    _ => AppStatusTone.primary,
  };
}
