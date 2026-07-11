import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/md_latex_body.dart';
import 'lecture_pager_widget.dart';

/// 讲义正文页 — 翻页 + 逐段展开
class LectureContentPage extends StatefulWidget {
  final int chapterId;
  final int initialPage;
  final LectureRepository? lectureRepository;

  const LectureContentPage({
    super.key,
    required this.chapterId,
    this.initialPage = 1,
    this.lectureRepository,
  });

  @override
  State<LectureContentPage> createState() => _LectureContentPageState();
}

class _LectureContentPageState extends State<LectureContentPage> {
  late final LectureRepository _repo;
  LectureContent? _content;
  LectureContentParsed? _parsed;
  int _pageIndex = 0;
  final Set<int> _revealedSet = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.lectureRepository ??
        LectureRepository(LectureDao(DatabaseProvider().lecturesDb));
    _pageIndex = widget.initialPage.clamp(1, 1) - 1; // 1-based → 0-based
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await _repo.getContent(widget.chapterId);
      final parsed = _repo.parseContent(content);
      if (!mounted) return;
      setState(() {
        _content = content;
        _parsed = parsed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  LecturePage? get _currentPage {
    if (_parsed == null || _pageIndex >= _parsed!.pages.length) return null;
    return _parsed!.pages[_pageIndex];
  }

  int get _totalBlocks => _currentPage?.blocks.length ?? 0;
  int get _revealedCount => _revealedSet.length;

  bool get _hasUnrevealed => _revealedCount < _totalBlocks - 1;
  bool get _hasRevealed => _revealedSet.isNotEmpty;

  void _onPrev() {
    if (_hasRevealed) {
      setState(() {
        final maxKey = _revealedSet.reduce((a, b) => a > b ? a : b);
        _revealedSet.remove(maxKey);
      });
    } else if (_pageIndex > 0) {
      setState(() {
        _pageIndex--;
        _revealedSet.clear();
      });
    }
  }

  void _onNext() {
    if (_hasUnrevealed) {
      setState(() {
        final next = _revealedCount + 1; // blocks[0] visible, blocks[1..N] revealed
        _revealedSet.add(next);
      });
    } else if (_pageIndex < (_parsed?.totalPages ?? 1) - 1) {
      setState(() {
        _pageIndex++;
        _revealedSet.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_content?.title ?? '讲义内容'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          if (_parsed != null && _parsed!.pages.isNotEmpty)
            LecturePagerWidget(
              currentPage: _pageIndex + 1,
              totalPages: _parsed!.totalPages,
              revealedCount: _revealedCount,
              totalBlocks: _totalBlocks,
              onPrev: _onPrev,
              onNext: _onNext,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载讲义…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final page = _currentPage;
    if (page == null || page.blocks.isEmpty) {
      return const Center(child: Text('讲义内容为空'));
    }

    final blocks = page.blocks;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.maxContentWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // blocks[0] 始终可见
            MdLatexBody(blocks[0], fontSize: 15),
            // blocks[1..N] 逐步展开
            for (int i = 1; i < blocks.length; i++)
              _buildRevealBlock(i, blocks[i]),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealBlock(int index, String content) {
    final visible = _revealedSet.contains(index);
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: MdLatexBody(content, fontSize: 15),
        ),
      ),
      crossFadeState: visible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}
