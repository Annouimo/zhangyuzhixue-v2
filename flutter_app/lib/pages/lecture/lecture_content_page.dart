import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/md_latex_body.dart';
import '../solve/widgets/knowledge_card_dialog.dart';
import 'lecture_pager_widget.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../../widgets/pop_back_guard.dart';

/// 讲义正文页 — 翻页 + 逐段展开
class LectureContentPage extends StatefulWidget {
  final int chapterId;
  final int initialPage;
  final LectureRepository? lectureRepository;

  LectureContentPage({
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
  final PopBackGuard _popGuard = PopBackGuard();
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
        LectureRepository(LectureDao(DatabaseProvider()));
    _pageIndex = widget.initialPage > 1 ? widget.initialPage - 1 : 0; // 1-based → 0-based
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
        // clamp pageIndex after knowing actual page count
        if (_pageIndex >= parsed.pages.length) {
          _pageIndex = parsed.pages.length - 1;
        }
        _loading = false;
      });
      AuditLogger.instance.page('LectureContentPage', {'hasContent': _content != null});
    } catch (e) { OperationLog.instance.error('lecture_content_page_load', e); 
      AuditLogger.instance.error('LectureContentPage._load', e);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
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
  /// 展示用展开数：含始终可见的 blocks[0]
  int get _displayRevealedCount => _revealedCount + 1;

  bool get _hasUnrevealed => _displayRevealedCount < _totalBlocks;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (await _popGuard.consume(context, 'lecture_content')) context.pop();
      },
      child: Scaffold(
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
              revealedCount: _displayRevealedCount,
              totalBlocks: _totalBlocks,
              onPrev: _onPrev,
              onNext: _onNext,
            ),
        ],
      ),
    ));
  }

  Widget _buildBody() {
      final colors = context.colors;
    if (_loading) return LoadingIndicator(message: '加载讲义…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final page = _currentPage;
    if (page == null || page.blocks.isEmpty) {
      return Center(child: Text('讲义内容为空'));
    }

    final blocks = page.blocks;
    final cardRefs = page.cardRefs;
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.baseSpacing),
      child: ConstrainedBox(
        constraints: BoxConstraints(
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
            // 知识标签
            if (cardRefs.isNotEmpty) ...[
              SizedBox(height: 20),
              Divider(height: 1),
              SizedBox(height: 12),
              Text(
                '相关知识',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: cardRefs.map((ref) => _buildKnowledgeChip(ref)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeChip(KnownCardRef ref) {
      final colors = context.colors;
    return ActionChip(
      avatar: Icon(Icons.lightbulb_outline, size: 16, color: colors.primary),
      label: Text(ref.title, style: TextStyle(fontSize: 13)),
      onPressed: () => KnowledgeCardDialog.show(
        context,
        title: ref.title,
        content: ref.content,
      ),
      backgroundColor: colors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildRevealBlock(int index, String content) {
    final visible = _revealedSet.contains(index);
    return AnimatedCrossFade(
      firstChild: SizedBox.shrink(),
      secondChild: Padding(
        padding: EdgeInsets.only(top: 12),
        child: MdLatexBody(content, fontSize: 15),
      ),
      crossFadeState: visible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 200),
    );
  }
}

