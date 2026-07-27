import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/lecture_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/lecture_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import 'lecture_chapters_page.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 讲义课程列表页（讲义 Tab 首页）
class LectureCoursesPage extends StatefulWidget {
  final LectureRepository? lectureRepository;

  const LectureCoursesPage({super.key, this.lectureRepository});

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
      AuditLogger.instance.page('LectureCoursesPage', {'courseCount': _courses?.length});
    } catch (e) {
      AuditLogger.instance.error('LectureCoursesPage._load', e);
      OperationLog.instance.error('LectureCoursesPage._load', e);
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
      appBar: AppBar(title: Text('讲义目录')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return LoadingIndicator(message: '加载讲义目录…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_courses == null || _courses!.isEmpty) {
      return EmptyPlaceholder(icon: Icons.menu_book,
        message: '暂无讲义',
      );
    }
    return ListView.separated(
        padding: EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _courses!.length,
        separatorBuilder: (_, _) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final course = _courses![index];
          return _CourseCard(
            name: course.name,
            chapterCount: course.chapterCount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LectureChaptersPage(
                  courseId: course.id,
                ),
              ),
            ),
          );
        },
      );
  }
}

/// 课程卡片
class _CourseCard extends StatelessWidget {
  final String name;
  final int chapterCount;
  final VoidCallback onTap;

  const _CourseCard({
    required this.name,
    required this.chapterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colors.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '共 $chapterCount 讲',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
