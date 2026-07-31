import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import '../router.dart';

/// 讲义课程列表页。
class LectureCoursesPage extends StatefulWidget {
  const LectureCoursesPage({
    super.key,
    this.lectureRepository,
    this.embedded = false,
  });

  final LectureRepository? lectureRepository;
  final bool embedded;

  @override
  State<LectureCoursesPage> createState() => _LectureCoursesPageState();
}

class _LectureCoursesPageState extends State<LectureCoursesPage> {
  late final LectureRepository _repo;
  List<Course>? _courses;
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
      final courses = await _repo.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loading = false;
      });
      AuditLogger.instance.page('LectureCoursesPage', {
        'courseCount': _courses?.length,
      });
    } catch (error) {
      OperationLog.instance.error('lecture_courses_page_load', error);
      AuditLogger.instance.error('LectureCoursesPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('讲义')),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载讲义目录…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final courses = _courses ?? [];
    if (courses.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.menu_book_outlined,
        message: '暂时没有讲义内容，后续会陆续上线',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppContentContainer(
        maxWidth: AppContentWidth.standard,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppNavigationList(
            children: courses
                .map(
                  (course) => AppNavigationListItem(
                    icon: Icons.menu_book_rounded,
                    title: course.name,
                    subtitle: '共 ${course.chapterCount} 讲',
                    semanticLabel: course.name,
                    onTap: () => RouterUtils.push(
                      context,
                      '/lecture/chapters?courseId=${course.id}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
