import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/loading_indicator.dart';

/// 学习偏好编辑页（新建/编辑）
class PreferenceEditPage extends StatefulWidget {
  final int? editId;
  final PreferenceRepository? preferenceRepository;

  const PreferenceEditPage({super.key, this.editId, this.preferenceRepository});

  @override
  State<PreferenceEditPage> createState() => _PreferenceEditPageState();
}

class _PreferenceEditPageState extends State<PreferenceEditPage> {
  late final PreferenceRepository _repo;
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
    if (widget.editId != null) {
      _loadExisting();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadExisting() async {
    try {
      await _repo.getEdit(widget.editId!);
      if (!mounted) return;
      _nameCtrl.text = '偏好 ${widget.editId}';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入名称'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.save(name: name, filter: const PreferenceFilter(years: [], regions: [], conceptTags: []));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功'), behavior: SnackBarBehavior.floating),
      );
      if (context.mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.editId != null ? '编辑偏好' : '新建偏好'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('保存', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
    body: _loading
        ? const LoadingIndicator()
        : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('加载失败', style: TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _loadExisting(); }, child: const Text('重试')),
              ]))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '偏好名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('筛选条件设置（后续扩展）',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
  );
}
