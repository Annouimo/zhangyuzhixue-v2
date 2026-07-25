import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/pop_back_guard.dart';
import '../router.dart';
import 'package:shared/shared.dart';
import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import '../solve/widgets/knowledge_card_dialog.dart';
import 'lecture_pager_widget.dart';

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
    if (_loading) return const LoadingIndicator(message: '加载讲义…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final page = _currentPage;
    if (page == null || page.blocks.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.menu_book_outlined,
        message: '这页讲义暂时没有内容',
      );
    }

    final blocks = page.blocks;
    final cardRefs = page.cardRefs;
    final progress = _totalBlocks > 0
        ? (_displayRevealedCount / _totalBlocks).clamp(0.0, 1.0)
        : 0.0;

    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppStatusBadge(
                  label: '第 ${_pageIndex + 1} / ${_parsed!.totalPages} 页',
                  tone: AppStatusTone.info,
                  icon: Icons.menu_book_outlined,
                  compact: true,
                ),
                const SizedBox(width: AppSpacing.xs),
                AppStatusBadge(
                  label: '已展开 $_displayRevealedCount / $_totalBlocks 段',
                  tone: _hasUnrevealed
                      ? AppStatusTone.neutral
                      : AppStatusTone.success,
                  icon: _hasUnrevealed
                      ? Icons.unfold_more_rounded
                      : Icons.check_circle_outline_rounded,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: context.colors.surfaceSubtle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MdLatexBody(blocks[0], fontSize: 16),
                  for (int index = 1; index < blocks.length; index++)
                    _buildRevealBlock(index, blocks[index]),
                  if (_hasUnrevealed) ...[
                    const SizedBox(height: AppSpacing.lg),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 18,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '使用下方“继续展开”逐段阅读，先思考再查看下一部分。',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.colors.onPrimaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (cardRefs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: '相关知识卡片',
                      subtitle: '点击标签可快速查看本页涉及的概念。',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: cardRefs
                          .map((ref) => _buildKnowledgeChip(ref))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeChip(KnownCardRef ref) {
    return ActionChip(
      avatar: Icon(
        Icons.lightbulb_outline_rounded,
        size: 17,
        color: context.colors.primary,
      ),
      label: Text(ref.title),
      onPressed: () => KnowledgeCardDialog.show(
        context,
        title: ref.title,
        content: ref.content,
      ),
    );
  }

  Widget _buildRevealBlock(int index, String content) {
    final visible = _revealedSet.contains(index);
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.emphasizedCurve,
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(color: context.colors.divider),
                  const SizedBox(height: AppSpacing.md),
                  MdLatexBody(content, fontSize: 16),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
