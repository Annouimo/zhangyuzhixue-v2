import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_folder_repository.dart';
import '../router.dart';

class PaperLibraryPage extends StatefulWidget {
  const PaperLibraryPage({super.key});

  @override
  State<PaperLibraryPage> createState() => _PaperLibraryPageState();
}

class _PaperLibraryPageState extends State<PaperLibraryPage> {
  late final QuestionLibraryRepository _repository;
  late final VirtualPaperRepository _virtualPaperRepository;
  late final PaperFolderRepository _folderRepository;
  final _searchController = TextEditingController();
  List<VirtualPaper>? _papers;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    final provider = DatabaseProvider();
    _repository = ExamRepository(QuestionDao(provider), ExamDao(provider));
    _virtualPaperRepository = LocalVirtualPaperRepository(
      QuestionDao(provider),
    );
    _folderRepository = PaperFolderRepository.local();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final papers = await _virtualPaperRepository.getVirtualPapers();
    if (mounted) setState(() => _papers = papers);
  }

  List<VirtualPaper> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    final papers = _papers ?? const [];
    if (query.isEmpty) return papers;
    return papers
        .where(
          (paper) => [
            paper.title,
            paper.year.toString(),
            paper.region,
            paper.examType,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  Future<void> _add(VirtualPaper paper, {bool openFolder = false}) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final folder = await _chooseFolder();
      if (folder == null) return;
      final questions = await _repository.getFilteredQuestions(
        SearchFilters(
          name: '',
          choiceCount: 0,
          fillCount: 0,
          solutionCount: 0,
          targetDifficulty: 0,
          years: [paper.year.toString()],
          regions: [paper.region],
          conceptTags: const [],
          knowledgeCards: const [],
          examTypes: [paper.examType],
        ),
      );
      await _folderRepository.addQuestions(
        folder.id,
        questions.map((question) => question.id),
      );
      if (!mounted) return;
      if (openFolder) {
        RouterUtils.push(
          context,
          '${AppRoutes.paperFolderDetail}?id=${folder.id}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已将 ${questions.length} 题加入“${folder.name}”')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<PaperFolderSummary?> _chooseFolder() async {
    var folders = await _folderRepository.list();
    if (folders.isEmpty) {
      final id = await _folderRepository.create('默认组卷夹');
      folders = await _folderRepository.list();
      if (folders.isEmpty) return null;
      final created = folders.where((folder) => folder.id == id);
      if (created.isNotEmpty) return created.first;
    }
    if (!mounted) return null;
    final selectedId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('加入哪个组卷夹？'),
        children: folders
            .map(
              (folder) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, folder.id),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  trailing: Text('${folder.questionCount} 题'),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (selectedId == null) return null;
    return folders.where((folder) => folder.id == selectedId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final papers = _visible;
    final grouped = <String, Map<int, List<VirtualPaper>>>{};
    for (final paper in papers) {
      grouped
          .putIfAbsent(paper.examType, () => {})
          .putIfAbsent(paper.year, () => [])
          .add(paper);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('套卷')),
      body: _papers == null
          ? const LoadingIndicator(message: '正在加载套卷')
          : AppContentContainer(
              maxWidth: AppContentWidth.standard,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索年份、地区或考试类型',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...grouped.entries.map(
                    (typeEntry) => ExpansionTile(
                      title: Text(typeEntry.key),
                      subtitle: Text(
                        '${typeEntry.value.values.fold<int>(0, (sum, items) => sum + items.length)} 套',
                      ),
                      children: typeEntry.value.entries
                          .map(
                            (yearEntry) => ExpansionTile(
                              title: Text('${yearEntry.key} 年'),
                              children: yearEntry.value
                                  .map(
                                    (paper) => ListTile(
                                      title: Text(paper.title),
                                      subtitle: Text(
                                        '${paper.year} · ${paper.region} · ${paper.questionCount} 题',
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        tooltip: '套卷操作',
                                        onSelected: (value) => _add(
                                          paper,
                                          openFolder: value == 'generate',
                                        ),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'add',
                                            child: Text('整套加入组卷夹'),
                                          ),
                                          PopupMenuItem(
                                            value: 'generate',
                                            child: Text('加入并打开组卷夹'),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _add(paper),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
