import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/empty_placeholder.dart';
import '../../../widgets/shared/error_placeholder.dart';
import 'widgets/paper_card.dart';

/// 发现组卷
class ExamExplorePage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamExplorePage({super.key, this.examRepository});

  @override
  State<ExamExplorePage> createState() => _ExamExplorePageState();
}

class _ExamExplorePageState extends State<ExamExplorePage> {
  late final ExamRepository _repo;
  List<ExploreExamSummary>? _list;
  bool _loading = true; String? _error;
  String _sortBy = 'created';

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(db.assetsDb), ExamDao(db.appDb),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final l = await _repo.getExploreList();
      if (!mounted) return;
      setState(() { _list = l..sort((a, b) => b.createdAt.compareTo(a.createdAt)); _loading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('发现组卷')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    if (_list == null || _list!.isEmpty) return const EmptyPlaceholder(icon: '🔍', message: '暂无公开组卷');
    return Column(
      children: [
        Container(
          width: double.infinity, color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['最新', '热度', '点赞', '收藏'].map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  selected: _sortBy == s,
                  onSelected: (_) => setState(() { _sortBy = s; }),
                  selectedColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
              )).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.baseSpacing),
              itemCount: _list!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = _list![i];
                return PaperCard(
                  title: e.name,
                  subtitle: '${e.likeCount} 赞 · ${e.collectCount} 收藏',
                  onTap: () => context.push('/exam/quicklook_other?id=${e.id}'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
