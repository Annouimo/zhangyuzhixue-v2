import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import '../router.dart';

/// 讲义章节目录。
class LectureChaptersPage extends StatefulWidget {
  const LectureChaptersPage({
    super.key,
    required this.courseId,
    this.lectureRepository,
  });

  final int courseId;
  final LectureRepository? lectureRepository;

  @override
  State<LectureChaptersPage> createState() => _LectureChaptersPageState();
}

class _LectureChaptersPageState extends State<LectureChaptersPage> {
  late final LectureRepository _repo;
  ChapterList? _chapterList;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.lectureRepository ??
        LectureRepository(LectureDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chapterList = await _repo.getChapters(widget.courseId);
      if (!mounted) return;
      setState(() {
        _chapterList = chapterList;
        _loading = false;
      });
      AuditLogger.instance.page('LectureChaptersPage', {
        'chapterCount': _chapterList?.items.length,
      });
    } catch (error) {
      OperationLog.instance.error('lecture_chapters_page_load', error);
      AuditLogger.instance.error('LectureChaptersPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_chapterList?.courseName ?? '章节目录')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载章节…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final chapterList = _chapterList;
    if (chapterList == null || chapterList.items.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.article_outlined,
        message: '这门课程暂时没有章节内容',
      );
    }

    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: chapterList.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final chapter = chapterList.items[index];
          return AppCard(
            onTap: () => RouterUtils.push(
              context,
              '/lecture/content?chapterId=${chapter.id}&page=1',
            ),
            semanticLabel: chapter.title,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const AppStatusBadge(
                  label: '阅读',
                  tone: AppStatusTone.info,
                  icon: Icons.arrow_forward_rounded,
                  compact: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
