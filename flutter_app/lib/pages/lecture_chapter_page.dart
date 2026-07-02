import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/lecture_repository.dart';

/// 章节列表页
class LectureChapterPage extends StatefulWidget {
  final int courseId;

  const LectureChapterPage({super.key, required this.courseId});

  @override
  State<LectureChapterPage> createState() => _LectureChapterPageState();
}

class _LectureChapterPageState extends State<LectureChapterPage> {
  List<Map<String, dynamic>>? _chapters;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LectureRepository.getChapters(widget.courseId);
    setState(() => _chapters = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('章节')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _chapters == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _chapters!.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final ch = _chapters![i];
                  return ListTile(
                    title: Text(ch['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/lecture-content?chapterId=${ch['id']}'),
                  );
                },
              ),
      ),
    );
  }
}
