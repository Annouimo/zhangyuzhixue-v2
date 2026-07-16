import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../domain/lecture_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'lecture_pager_widget.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await widget.repo.getContent(widget.chapterId);
      final parsed = widget.repo.parseContent(content);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        // clamp pageIndex after knowing actual page count
        if (_pageIndex >= parsed.pages.length) {
          _pageIndex = parsed.pages.length - 1;
        }
        _loading = false;
      });
      AuditLogger.instance.page('LectureContentPage', {
        'chapterId': widget.chapterId,
        'pageCount': parsed.pages.length,
      });
    } catch (e) {
      AuditLogger.instance.error('LectureContentPage._load', e);
      OperationLog.instance.error('LectureContentPage._load', e);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterTitle),
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
    final cardRefs = page.cardRefs;
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
            // 知识标签
            if (cardRefs.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                '相关知识',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
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
    return ActionChip(
      avatar: const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
      label: Text(ref.title, style: const TextStyle(fontSize: 13)),
      onPressed: () => _showKnowledgeCard(context, ref.title, ref.content),
      backgroundColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showKnowledgeCard(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: SingleChildScrollView(
          child: MdLatexBody(content, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealBlock(int index, String content) {
    final visible = _revealedSet.contains(index);
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: MdLatexBody(content, fontSize: 15),
      ),
      crossFadeState: visible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}
