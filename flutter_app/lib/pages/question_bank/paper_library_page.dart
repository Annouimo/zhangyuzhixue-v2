import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_content.dart';
import '../exam/exam_quicklook_page.dart';
import '../exam/widgets/paper_card.dart';

class PaperLibraryPage extends StatefulWidget {
  const PaperLibraryPage({super.key, this.embedded = false, this.regions});

  final bool embedded;
  final List<String>? regions;

  @override
  State<PaperLibraryPage> createState() => _PaperLibraryPageState();
}

class _PaperLibraryPageState extends State<PaperLibraryPage> {
  late final ExamRepository _repository;
  late final VirtualPaperRepository _virtualPaperRepository;
  final _searchController = TextEditingController();
  List<VirtualPaper>? _papers;

  @override
  void initState() {
    super.initState();
    final provider = DatabaseProvider();
    _repository = ExamRepository(QuestionDao(provider), ExamDao(provider));
    _virtualPaperRepository = LocalVirtualPaperRepository(
      QuestionDao(provider),
    );
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
    final regions = widget.regions;
    final scoped = regions == null
        ? papers
        : papers.where((paper) => regions.contains(paper.region)).toList();
    if (query.isEmpty) return scoped;
    return scoped
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

  void _openPaper(VirtualPaper paper) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamQuicklookPage(
          virtualPaper: VirtualPaperRef(
            year: paper.year,
            examType: paper.examType,
            region: paper.region,
          ),
          examRepository: _repository,
        ),
      ),
    );
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
    final body = _papers == null
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
                                  (paper) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: PaperCard(
                                      title: paper.title,
                                      subtitle:
                                          '${paper.year} · ${paper.region} · ${paper.questionCount} 题',
                                      trailing: '整卷',
                                      onTap: () => _openPaper(paper),
                                    ),
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
          );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('浏览试卷')),
      body: body,
    );
  }
}
