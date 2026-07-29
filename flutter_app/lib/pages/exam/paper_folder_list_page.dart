import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../domain/paper_folder_repository.dart';
import '../router.dart';

class PaperFolderListPage extends StatefulWidget {
  const PaperFolderListPage({super.key, this.repository});

  final PaperFolderRepository? repository;

  @override
  State<PaperFolderListPage> createState() => _PaperFolderListPageState();
}

class _PaperFolderListPageState extends State<PaperFolderListPage> {
  late final PaperFolderRepository _repository =
      widget.repository ?? PaperFolderRepository.local();
  List<PaperFolderSummary>? _folders;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final folders = await _repository.list();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '组卷夹加载失败，请稍后重试');
    }
  }

  Future<void> _create() async {
    final controller = TextEditingController(text: '新组卷夹');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建组卷夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final id = await _repository.create(name);
    if (!mounted) return;
    await RouterUtils.push(context, '${AppRoutes.paperFolderDetail}?id=$id');
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('组卷夹'),
      actions: [
        IconButton(
          tooltip: '新建组卷夹',
          onPressed: _create,
          icon: const Icon(Icons.create_new_folder_outlined),
        ),
      ],
    ),
    body: _error != null
        ? ErrorPlaceholder(message: _error!, onRetry: _load)
        : _folders == null
        ? const LoadingIndicator(message: '正在加载组卷夹')
        : _folders!.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyPlaceholder(
                  icon: Icons.folder_copy_outlined,
                  message: '还没有组卷夹',
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: '新建组卷夹',
                  icon: Icons.create_new_folder_outlined,
                  expanded: false,
                  onPressed: _create,
                ),
              ],
            ),
          )
        : AppContentContainer(
            maxWidth: AppContentWidth.standard,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: _folders!.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final folder = _folders![index];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  subtitle: Text(
                    '${folder.questionCount} 题 · ${_time(folder.updatedAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await RouterUtils.push(
                      context,
                      '${AppRoutes.paperFolderDetail}?id=${folder.id}',
                    );
                    await _load();
                  },
                );
              },
            ),
          ),
    floatingActionButton: FloatingActionButton(
      tooltip: '新建组卷夹',
      onPressed: _create,
      child: const Icon(Icons.add),
    ),
  );

  String _time(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
