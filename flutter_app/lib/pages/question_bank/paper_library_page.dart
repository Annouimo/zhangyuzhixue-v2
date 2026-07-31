import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_content.dart';
import '../exam/exam_quicklook_page.dart';

enum PaperLibraryMode { all, real, mock }

class PaperLibraryPage extends StatefulWidget {
  const PaperLibraryPage({
    super.key,
    this.embedded = false,
    this.regions,
    this.mode = PaperLibraryMode.all,
  });

  final bool embedded;
  final List<String>? regions;
  final PaperLibraryMode mode;

  @override
  State<PaperLibraryPage> createState() => _PaperLibraryPageState();
}

class _PaperLibraryPageState extends State<PaperLibraryPage> {
  late final ExamRepository _repository;
  late final VirtualPaperRepository _virtualPaperRepository;
  List<VirtualPaper>? _papers;
  String _mockType = '一模';

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

  Future<void> _load() async {
    final papers = await _virtualPaperRepository.getVirtualPapers();
    if (mounted) setState(() => _papers = papers);
  }

  List<VirtualPaper> get _visible {
    final papers = _papers ?? const [];
    final regions = widget.regions;
    final scoped = regions == null
        ? papers
        : papers.where((paper) => regions.contains(paper.region)).toList();
    return switch (widget.mode) {
      PaperLibraryMode.real =>
        scoped
            .where((paper) => paper.examType.contains('高考'))
            .toList(growable: false),
      PaperLibraryMode.mock =>
        scoped
            .where((paper) => paper.examType.contains(_mockType))
            .toList(growable: false),
      PaperLibraryMode.all => scoped,
    };
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
    final grouped = <int, List<VirtualPaper>>{};
    for (final paper in papers) {
      grouped.putIfAbsent(paper.year, () => []).add(paper);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final body = _papers == null
        ? const LoadingIndicator(message: '正在加载套卷')
        : AppContentContainer(
            maxWidth: AppContentWidth.standard,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                if (widget.mode == PaperLibraryMode.mock) ...[
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ['一模', '二模']
                          .map(
                            (type) => ChoiceChip(
                              label: Text(type),
                              selected: _mockType == type,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _mockType = type),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                ...years.map((year) {
                  final yearPapers = grouped[year]!
                    ..sort((a, b) => a.region.compareTo(b.region));
                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    childrenPadding: EdgeInsets.zero,
                    shape: Border(
                      bottom: BorderSide(color: context.colors.divider),
                    ),
                    collapsedShape: Border(
                      bottom: BorderSide(color: context.colors.divider),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$year年',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${yearPapers.length}套',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                    children: yearPapers
                        .map(
                          (paper) => Column(
                            children: [
                              ListTile(
                                minTileHeight: 56,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                hoverColor: context.colors.surfaceSubtle,
                                title: Text(paper.title),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${paper.questionCount}题',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context.colors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: context.colors.textSecondary,
                                    ),
                                  ],
                                ),
                                onTap: () => _openPaper(paper),
                              ),
                              Divider(
                                height: 1,
                                indent: AppSpacing.md,
                                color: context.colors.divider,
                              ),
                            ],
                          ),
                        )
                        .toList(growable: false),
                  );
                }),
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
