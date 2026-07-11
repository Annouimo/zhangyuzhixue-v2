import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_placeholder.dart';
import '../router.dart';
import '../../data/debug/audit_logger.dart';

/// 学习偏好列表页（匹配 preference_list.html）
class PreferenceListPage extends StatefulWidget {
  final PreferenceRepository? preferenceRepository;

  const PreferenceListPage({super.key, this.preferenceRepository});

  @override
  State<PreferenceListPage> createState() => _PreferenceListPageState();
}

class _PreferenceListPageState extends State<PreferenceListPage> {
  late final PreferenceRepository _repo;
  bool _loading = true;
  List<PreferenceSummary> _preferences = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _repo.getList();
      if (!mounted) return;
      setState(() {
        _preferences = list;
        _loading = false;
      });
      AuditLogger.instance.page('PreferenceListPage', {'presetCount': _preferences.length});
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(int id, int index) async {
    try {
      await _repo.delete(id);
      if (!mounted) return;
      setState(() => _preferences.removeAt(index));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习偏好管理')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.preferenceEdit),
        icon: const Icon(Icons.add),
        label: const Text('新建偏好'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator();
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_preferences.isEmpty) {
      return const EmptyPlaceholder(
        icon: '📋',
        message: '暂无学习偏好，快去创建一个吧',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _preferences.length,
        itemBuilder: (context, index) {
          final p = _preferences[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 18)),
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
                        onPressed: () => context.push(AppRoutes.preferenceEdit),
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
      ),
    );
  }
}
