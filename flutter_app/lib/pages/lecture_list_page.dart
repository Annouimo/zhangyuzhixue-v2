import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/lecture_repository.dart';

/// 讲义列表页（课程列表）
class LectureListPage extends StatefulWidget {
  const LectureListPage({super.key});

  @override
  State<LectureListPage> createState() => _LectureListPageState();
}

class _LectureListPageState extends State<LectureListPage> {
  List<Map<String, dynamic>>? _courses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LectureRepository.getCourses();
    setState(() => _courses = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('讲义')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _courses == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _courses!.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final c = _courses![i];
                  return ListTile(
                    title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/lecture-chapter?courseId=${c['id']}'),
                  );
                },
              ),
      ),
    );
  }
}
