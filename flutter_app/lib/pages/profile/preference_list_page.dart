import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/empty_placeholder.dart';

import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';

/// 常用选题范围管理。
class PreferenceListPage extends StatefulWidget {
  const PreferenceListPage({
    super.key,
    this.preferenceRepository,
  });

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
      appBar: AppBar(title: const Text('我的筛选方案')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建方案'),
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
