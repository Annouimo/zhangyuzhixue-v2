import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import 'lecture_content_page.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 章节目录页
class LectureChaptersPage extends StatefulWidget {
  final int courseId;
  final LectureRepository? lectureRepository;

  const LectureChaptersPage({
    super.key,
    required this.courseId,
    this.lectureRepository,
  });

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
    _repo = widget.lectureRepository ??
        LectureRepository(LectureDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cl = await _repo.getChapters(widget.courseId);
      if (!mounted) return;
      setState(() {
        _chapterList = cl;
        _loading = false;
      });
      AuditLogger.instance.page('LectureChaptersPage', {'chapterCount': _chapterList?.items.length});
    } catch (e) {
      AuditLogger.instance.error('LectureChaptersPage._load', e);
      OperationLog.instance.error('LectureChaptersPage._load', e);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chapterList?.courseName ?? '章节列表'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载章节…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_chapterList == null || _chapterList!.items.isEmpty) {
      return const EmptyPlaceholder(icon: Icons.article,
        message: '暂无章节',
      );
    }
    return ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _chapterList!.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final chapter = _chapterList!.items[index];
          return _ChapterCard(
            title: chapter.title,
            index: index + 1,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LectureContentPage(
                  chapterId: chapter.id,
                  chapterTitle: chapter.title,
                  repo: _repo,
                ),
              ),
            ),
          );
        },
      );
  }
}

/// 章节卡片
class _ChapterCard extends StatelessWidget {
  final String title;
  final int index;
  final VoidCallback onTap;

  const _ChapterCard({
    required this.title,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
