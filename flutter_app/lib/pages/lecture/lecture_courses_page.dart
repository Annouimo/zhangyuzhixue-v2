import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import '../router.dart';

/// 讲义课程列表页。
class LectureCoursesPage extends StatefulWidget {
  const LectureCoursesPage({super.key, this.lectureRepository, this.embedded = false});

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
    return Scaffold(appBar: AppBar(title: const Text('讲义')), body: body);
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

    final chapterCount = courses.fold<int>(
      0,
      (sum, course) => sum + course.chapterCount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppContentContainer(
        maxWidth: AppContentWidth.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            AppSectionHeader(
              title: '选择课程',
              subtitle: '${courses.length} 门课程 · 共 $chapterCount 讲',
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= AppBreakpoints.expanded
                    ? 3
                    : constraints.maxWidth >= AppBreakpoints.compact
                    ? 2
                    : 1;
                const gap = AppSpacing.md;
                final width = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: courses
                      .map(
                        (course) => SizedBox(
                          width: width,
                          child: _CourseCard(
                            name: course.name,
                            chapterCount: course.chapterCount,
                            onTap: () => RouterUtils.push(
                              context,
                              '/lecture/chapters?courseId=${course.id}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.name,
    required this.chapterCount,
    required this.onTap,
  });

  final String name;
  final int chapterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      semanticLabel: name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(Icons.menu_book_rounded, color: colors.primary),
              ),
              const Spacer(),
              Icon(AppIcons.chevronRight, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '共 $chapterCount 讲 · 点击进入目录',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
