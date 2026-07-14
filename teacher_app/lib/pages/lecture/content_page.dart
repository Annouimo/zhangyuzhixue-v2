import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../domain/lecture_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/md_latex_body.dart';
import 'pager_widget.dart';

/// 讲义正文页 — 翻页 + 逐段展开
class LectureContentPage extends StatefulWidget {
  final int chapterId;
  final String chapterTitle;
  final LectureRepository repo;

  const LectureContentPage({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.repo,
  });

  @override
  State<LectureContentPage> createState() => _LectureContentPageState();
}

class _LectureContentPageState extends State<LectureContentPage> {
  LectureContent? _content;
  LectureContentParsed? _parsed;
  int _pageIndex = 0;
  final Set<int> _revealedSet = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final content = await widget.repo.getContent(widget.chapterId);
      final parsed = widget.repo.parseContent(content);
      if (!mounted) return;
      setState(() { _content = content; _parsed = parsed; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _prev() {
    if (_revealedSet.isNotEmpty) {
      // 先收回最后展开的块
      final last = _revealedSet.reduce((a, b) => a > b ? a : b);
      setState(() => _revealedSet.remove(last));
    } else if (_pageIndex > 0) {
      setState(() {
        _pageIndex--;
        _revealedSet.clear();
      });
    }
  }

  void _next() {
    final page = _parsed!.pages[_pageIndex];
    final firstUnrevealed = page.blocks.length - _revealedSet.length;
    if (firstUnrevealed > 0) {
      // 展开下一个未展开的块
      final nextIdx = page.blocks.length - firstUnrevealed;
      setState(() => _revealedSet.add(nextIdx));
    } else if (_pageIndex < _parsed!.totalPages - 1) {
      setState(() { _pageIndex++; _revealedSet.clear(); });
    }
  }

  void _showKnowledgeCard(KnownCardRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ref.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              MdLatexBody(ref.content),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_content?.title ?? widget.chapterTitle, style: const TextStyle(fontSize: 15)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载讲义…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_parsed == null) return const SizedBox.shrink();

    final page = _parsed!.pages[_pageIndex];
    final totalRevealed = _parsed!.pages
        .take(_pageIndex)
        .fold(0, (sum, p) => sum + p.blocks.length) + _revealedSet.length;
    final totalBlocks = _parsed!.pages.fold(0, (sum, p) => sum + p.blocks.length);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            children: [
              ...List.generate(page.blocks.length, (i) {
                final isRevealed = _revealedSet.contains(i);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isRevealed)
                        InkWell(
                          onTap: () => setState(() => _revealedSet.add(i)),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('点击展开',
                                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isRevealed) MdLatexBody(page.blocks[i]),
                    ],
                  ),
                );
              }),
              // 知识卡片引用
              if (page.cardRefs.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text('📖 关联知识卡片',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: page.cardRefs.map((ref) => ActionChip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
                    label: Text(ref.title, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _showKnowledgeCard(ref),
                    side: BorderSide.none,
                    backgroundColor: const Color(0xFFFFF8E1),
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        LecturePagerWidget(
          currentPage: _pageIndex + 1,
          totalPages: _parsed!.totalPages,
          revealedCount: totalRevealed,
          totalBlocks: totalBlocks,
          onPrev: _prev,
          onNext: _next,
        ),
      ],
    );
  }
}
