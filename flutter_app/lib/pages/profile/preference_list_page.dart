import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_feature_banner.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/empty_placeholder.dart';

import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';

/// 学习偏好管理。
class PreferenceListPage extends StatefulWidget {
  const PreferenceListPage({super.key, this.preferenceRepository});

  final PreferenceRepository? preferenceRepository;

  @override
  State<PreferenceListPage> createState() => _PreferenceListPageState();
}

class _PreferenceListPageState extends State<PreferenceListPage> {
  late final PreferenceRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<PreferenceSummary>>> _loadKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo =
        widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider()));
  }

  Future<void> _delete(int id, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
        title: const Text('删除学习偏好？'),
        content: const Text('删除后无法恢复，但不会影响已有的练习记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _loadKey.currentState?.optimisticUpdate((list) {
      list.removeAt(index);
      return list;
    });
    try {
      await _repo.delete(id);
    } catch (error) {
      OperationLog.instance.error('preference_list_page_delete', error);
      AuditLogger.instance.error('PreferenceListPage._delete', error);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，已恢复列表')));
      _loadKey.currentState?.refresh();
    }
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
      appBar: AppBar(title: const Text('学习偏好')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建偏好'),
      ),
      body: AsyncLoadWidget<List<PreferenceSummary>>(
        contentIsScrollable: true,
        key: _loadKey,
        onLoad: _repo.getList,
        loadingMessage: '正在加载学习偏好…',
        emptyWidget: EmptyPlaceholder(
          icon: Icons.tune_rounded,
          message: '还没有学习偏好。创建一组筛选条件后，推荐页会更了解你想练习的内容。',
        ),
        builder: (context, preferences) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AuditLogger.instance.page('PreferenceListPage', {
              'presetCount': preferences.length,
            });
          });
          return AppContentContainer(
            maxWidth: AppContentWidth.standard,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: [
                AppFeatureBanner(
                  icon: Icons.tune_rounded,
                  eyebrow: '推荐设置',
                  title: '管理你的练习偏好',
                  subtitle: '为不同目标创建独立偏好，例如选择题专项、函数复习或某地区真题。',
                  action: AppButton(
                    label: '新建偏好',
                    icon: Icons.add_rounded,
                    onPressed: () => _openEditor(),
                    expanded: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: '已保存偏好',
                  subtitle: '共 ${preferences.length} 组，可随时编辑或删除。',
                ),
                const SizedBox(height: AppSpacing.md),
                ...preferences.asMap().entries.map((entry) {
                  final index = entry.key;
                  final preference = entry.value;
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    onTap: () => _openEditor(preference.id),
                    semanticLabel: '编辑偏好 ${preference.name}',
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
                                    label: '已启用',
                                    tone: AppStatusTone.success,
                                    compact: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                preference.summary,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openEditor(preference.id),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('编辑'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _delete(preference.id, index),
                                    style: TextButton.styleFrom(
                                      foregroundColor: context.colors.error,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('删除'),
                                  ),
                                ],
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
          );
        },
      ),
    );
  }
}
