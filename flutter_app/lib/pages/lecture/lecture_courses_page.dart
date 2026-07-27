import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import '../router.dart';

/// 讲义课程列表页。
class LectureCoursesPage extends StatefulWidget {
  const LectureCoursesPage({super.key, this.lectureRepository});

  final LectureRepository? lectureRepository;

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
      final courses = await _repo.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loading = false;
      });
      AuditLogger.instance.page(
        'LectureCoursesPage',
        {'courseCount': _courses?.length},
      );
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('讲义目录')),
        body: _buildBody(),
      );

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
            AppFeatureBanner(
              eyebrow: '课程讲义',
              icon: Icons.menu_book_rounded,
              title: '按章节理解知识脉络',
              subtitle: '讲义支持逐段展开，适合在做题前预习，也可以在错题后快速回顾相关知识。',
              footer: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppStatusBadge(
                    label: '${courses.length} 门课程',
                    tone: AppStatusTone.info,
                    icon: Icons.school_outlined,
                    compact: true,
                  ),
                  AppStatusBadge(
                    label: '共 $chapterCount 讲',
                    tone: AppStatusTone.success,
                    icon: Icons.library_books_outlined,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: '选择课程',
              subtitle: '进入课程后可以按章节顺序阅读。',
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
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colors.primary,
                ),
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
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
