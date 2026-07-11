import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../widgets/shared/loading_indicator.dart';

/// 学习偏好列表页（匹配 preference_list.html）
class PreferenceListPage extends StatefulWidget {
  const PreferenceListPage({super.key});

  @override
  State<PreferenceListPage> createState() => _PreferenceListPageState();
}

class _PreferenceListPageState extends State<PreferenceListPage> {
  bool _loading = true;
  final List<Map<String, String>> _preferences = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // TODO: 从数据层读取偏好列表
    // 目前展示空状态，后续通过 Repository 接入
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习偏好管理')),
      body: _loading
          ? const LoadingIndicator()
          : _preferences.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      '暂无学习偏好，快去创建一个吧',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _preferences.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _preferences.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/preference/edit'),
                            icon: const Icon(Icons.add),
                            label: const Text('新建偏好'),
                          ),
                        ),
                      );
                    }
                    final p = _preferences[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] ?? '',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p['summary'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => context.push('/preference/edit'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('编辑'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    // TODO: 删除偏好
                                  },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/preference/edit'),
        icon: const Icon(Icons.add),
        label: const Text('新建偏好'),
      ),
    );
  }
}
