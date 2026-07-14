import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../domain/lecture_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/shared/empty_placeholder.dart';
import 'content_page.dart';

/// 章节目录页
class LectureChaptersPage extends StatefulWidget {
  final int courseId;
  final String courseName;
  final LectureRepository repo;

  const LectureChaptersPage({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.repo,
  });

  @override
  State<LectureChaptersPage> createState() => _LectureChaptersPageState();
}

class _LectureChaptersPageState extends State<LectureChaptersPage> {
  ChapterList? _chapterList;
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
      final cl = await widget.repo.getChapters(widget.courseId);
      if (!mounted) return;
      setState(() { _chapterList = cl; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chapterList?.courseName ?? widget.courseName)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载章节…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_chapterList == null || _chapterList!.items.isEmpty) {
      return const EmptyPlaceholder(icon: Icons.article, message: '暂无章节');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      itemCount: _chapterList!.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chapter = _chapterList!.items[index];
        return Card(
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LectureContentPage(
                chapterId: chapter.id,
                chapterTitle: chapter.title,
                repo: widget.repo,
              ),
            )),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(chapter.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
