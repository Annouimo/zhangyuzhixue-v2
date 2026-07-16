import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/empty_placeholder.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';
import '../../data/debug/audit_logger.dart';
import '../../../data/debug/operation_log.dart';

/// 学习偏好列表页（匹配 preference_list.html）
class PreferenceListPage extends StatefulWidget {
  final PreferenceRepository? preferenceRepository;

  const PreferenceListPage({super.key, this.preferenceRepository});

  @override
  State<PreferenceListPage> createState() => _PreferenceListPageState();
}

class _PreferenceListPageState extends State<PreferenceListPage> {
  late final PreferenceRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<PreferenceSummary>>> _loadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo = widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider()));
  }

  Future<void> _delete(int id, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除该偏好吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // 乐观删除
    _loadKey.currentState?.optimisticUpdate((list) {
      list.removeAt(index);
      return list;
    });
    try {
      await _repo.delete(id);
    } catch (e) {
      OperationLog.instance.error('preference_list_page_load', e);
      AuditLogger.instance.error('PreferenceListPage._delete', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
      // 失败后刷新列表，恢复实际数据
      _loadKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习偏好管理')),
      body: AsyncLoadWidget<List<PreferenceSummary>>(
        key: _loadKey,
        onLoad: () => _repo.getList(),
        emptyWidget: const EmptyPlaceholder(
          icon: Icons.assignment,
          message: '还没有设置学习偏好，点击右上角 + 新建',
        ),
        builder: (ctx, list) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AuditLogger.instance.page('PreferenceListPage', {'presetCount': list.length});
          });
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.summary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              await context.push('${AppRoutes.preferenceEdit}?id=${p.id}');
                              _loadKey.currentState?.refresh();
                            },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('编辑'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _delete(p.id, index),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.preferenceEdit);
          _loadKey.currentState?.refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('新建偏好'),
      ),
    );
  }
}
