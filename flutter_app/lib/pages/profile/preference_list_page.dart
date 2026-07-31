import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_action_sheet.dart';
import 'package:shared/widgets/app_dialog.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_selection.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:shared/widgets/empty_placeholder.dart';

import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';

/// 常用选题范围管理。
class PreferenceListPage extends StatefulWidget {
  const PreferenceListPage({super.key, this.preferenceRepository});

  final PreferenceRepository? preferenceRepository;

  @override
  State<PreferenceListPage> createState() => _PreferenceListPageState();
}

class _PreferenceListPageState extends State<PreferenceListPage> {
  late final PreferenceRepository _repo;
  final AppSelectionController<int> _selection = AppSelectionController<int>();
  final GlobalKey<AsyncLoadWidgetState<List<PreferenceSummary>>> _loadKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo =
        widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider()));
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) => setState(() => _selection.toggle(id));
  void _clearSelection() => setState(_selection.clear);

  Future<void> _copySelected(List<PreferenceSummary> preferences) async {
    final selected = preferences.where(
      (item) => _selection.isSelected(item.id),
    );
    var copied = 0;
    for (final preference in selected) {
      final edit = await _repo.getEdit(preference.id);
      await _repo.save(name: '${preference.name}（副本）', filter: edit.filter);
      copied++;
    }
    _clearSelection();
    _loadKey.currentState?.refresh();
    if (mounted) AppToast.success(context, '已复制 $copied 个筛选方案');
  }

  Future<void> _deleteSelected(List<PreferenceSummary> preferences) async {
    final selected = preferences
        .where((item) => _selection.isSelected(item.id))
        .toList(growable: false);
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除所选筛选方案？',
      message: '将删除 ${selected.length} 个筛选方案，删除后无法恢复。',
      icon: Icons.delete_outline,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    for (final preference in selected) {
      await _repo.delete(preference.id);
    }
    _clearSelection();
    _loadKey.currentState?.refresh();
  }

  Future<void> _manageSelected(List<PreferenceSummary> preferences) async {
    final action = await AppActionSheet.show<String>(
      context,
      title: '管理所选方案 · ${_selection.selectedCount} 个',
      items: const [
        AppActionSheetItem(
          value: 'copy',
          label: '复制所选方案',
          icon: Icons.copy_outlined,
          detail: '生成名称带“副本”的新方案',
        ),
        AppActionSheetItem(
          value: 'delete',
          label: '删除所选方案',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'copy') await _copySelected(preferences);
    if (action == 'delete') await _deleteSelected(preferences);
  }

  Future<void> _openEditor([int? id]) async {
    final route = id == null
        ? AppRoutes.preferenceEdit
        : '${AppRoutes.preferenceEdit}?id=$id';
    await RouterUtils.push(context, route);
    _loadKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的筛选方案'),
        actions: [
          if (MediaQuery.sizeOf(context).width < 600)
            IconButton(
              tooltip: '新建方案',
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
            )
          else
            TextButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建方案'),
            ),
        ],
      ),
      body: AsyncLoadWidget<List<PreferenceSummary>>(
        contentIsScrollable: true,
        key: _loadKey,
        onLoad: _repo.getList,
        loadingMessage: '正在加载筛选方案…',
        emptyWidget: EmptyPlaceholder(
          icon: Icons.tune_rounded,
          message: '还没有筛选方案。可以把经常使用的查找条件保存到这里。',
        ),
        builder: (context, preferences) {
          _selection.retain(preferences.map((item) => item.id));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AuditLogger.instance.page('PreferenceListPage', {
              'presetCount': preferences.length,
            });
          });
          return Column(
            children: [
              Expanded(
                child: AppContentContainer(
                  maxWidth: AppContentWidth.standard,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    children: [
                      ...preferences.map((preference) {
                        return AppCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          onTap: () => _openEditor(preference.id),
                          semanticLabel: '编辑筛选方案 ${preference.name}',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: context.colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.medium,
                                  ),
                                ),
                                child: Icon(
                                  Icons.bookmark_outline_rounded,
                                  color: context.colors.primary,
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
                                            preference.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ),
                                        const AppStatusBadge(
                                          label: '已保存',
                                          tone: AppStatusTone.success,
                                          compact: true,
                                        ),
                                        AppSelectionToggle(
                                          selected: _selection.isSelected(
                                            preference.id,
                                          ),
                                          onPressed: () =>
                                              _toggleSelection(preference.id),
                                          selectTooltip: '选择筛选方案',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      preference.summary,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context.colors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              AppSelectionActionBar(
                selectedCount: _selection.selectedCount,
                totalCount: preferences.length,
                itemUnit: ' 个',
                onSelectAll: () => setState(
                  () =>
                      _selection.selectAll(preferences.map((item) => item.id)),
                ),
                onClear: _clearSelection,
                actionLabel: '管理方案',
                actionIcon: Icons.tune_rounded,
                onAction: () => _manageSelected(preferences),
              ),
            ],
          );
        },
      ),
    );
  }
}
