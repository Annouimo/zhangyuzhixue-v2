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
      if (mounted) setState(() => _error = '试题篮加载失败，请稍后重试');
    }
  }

  Future<void> _create() async {
    final name = await AppDialog.prompt(
      context,
      title: '新建试题篮',
      initialValue: '新试题篮',
      confirmLabel: '创建',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    final id = await _repository.create(name);
    if (!mounted) return;
    await RouterUtils.push(context, '${AppRoutes.paperFolderDetail}?id=$id');
    await _load();
  }

  Future<void> _rename(PaperFolderSummary folder) async {
    final name = await AppDialog.prompt(
      context,
      title: '重命名试题篮',
      initialValue: folder.name,
      confirmLabel: '保存',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    await _repository.rename(folder.id, name);
    await _load();
  }

  Future<void> _delete(PaperFolderSummary folder) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除试题篮？',
      message: '将删除“${folder.name}”，已生成的试卷不受影响。',
      icon: Icons.delete_outline_rounded,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    await _repository.delete(folder.id);
    await _load();
  }

  Future<void> _showFolderMenu(PaperFolderSummary folder) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('重命名'),
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制试题篮'),
              onTap: () => Navigator.pop(sheetContext, 'copy'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.colors.error),
              title: Text(
                '删除试题篮',
                style: TextStyle(color: context.colors.error),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'rename') await _rename(folder);
    if (action == 'copy') {
      await _repository.copyFolder(folder.id);
      await _load();
    }
    if (action == 'delete') await _delete(folder);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('试题篮'),
      actions: [
        IconButton(
          tooltip: '新建试题篮',
          onPressed: _create,
          icon: const Icon(Icons.create_new_folder_outlined),
        ),
      ],
    ),
    body: _error != null
        ? ErrorPlaceholder(message: _error!, onRetry: _load)
        : _folders == null
        ? const LoadingIndicator(message: '正在加载试题篮')
        : _folders!.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyPlaceholder(
                  icon: Icons.folder_copy_outlined,
                  message: '还没有试题篮',
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: '新建试题篮',
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
                return GestureDetector(
                  onLongPress: () => _showFolderMenu(folder),
                  onSecondaryTap: () => _showFolderMenu(folder),
                  child: ListTile(
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
                  ),
                );
              },
            ),
          ),
    floatingActionButton: FloatingActionButton(
      tooltip: '新建试题篮',
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
