import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/assignment_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/assignment_repository.dart';
import '../../data/prefs/app_prefs.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/shared/empty_placeholder.dart';
import '../../data/debug/audit_logger.dart';

/// 作业列表页（作业 Tab 首页）
class HomeworkListPage extends StatefulWidget {
  final AssignmentRepository? assignmentRepository;

  const HomeworkListPage({super.key, this.assignmentRepository});

  @override
  State<HomeworkListPage> createState() => _HomeworkListPageState();
}

class _HomeworkListPageState extends State<HomeworkListPage> {
  late final AssignmentRepository _repo;
  List<AssignmentSummary>? _assignments;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.assignmentRepository ??
        AssignmentRepository(
          AssignmentDao(DatabaseProvider().lecturesDb),
          ProgressDao(DatabaseProvider().appDb),
          QuestionDao(DatabaseProvider().assetsDb),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getPending();
      if (!mounted) return;
      AppPrefs().setPendingHomeworkCount(list.length);
      setState(() {
        _assignments = list;
        _loading = false;
      });
      AuditLogger.instance.page('HomeworkListPage', {'total': _assignments?.length});
    } catch (e) {
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
      appBar: AppBar(title: const Text('作业')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载作业…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_assignments == null || _assignments!.isEmpty) {
      return const EmptyPlaceholder(
        icon: '📋',
        message: '暂无待办作业',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _assignments!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final a = _assignments![index];
          return _AssignmentCard(
            title: a.title,
            courseName: a.courseName,
            doneCount: a.doneCount,
            totalCount: a.totalCount,
            deadlineDays: a.deadlineDays,
            onTap: () => context.push('/homework/detail?id=${a.id}'),
          );
        },
      ),
    );
  }
}

/// 作业卡片
class _AssignmentCard extends StatelessWidget {
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int deadlineDays;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (courseName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            courseName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppColors.success),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$doneCount/$totalCount',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (deadlineDays > 0) ...[
                const SizedBox(height: 8),
                Text(
                  deadlineDays <= 3
                      ? '剩余 $deadlineDays 天'
                      : '剩余 $deadlineDays 天',
                  style: TextStyle(
                    fontSize: 12,
                    color: deadlineDays <= 3 ? AppColors.error : AppColors.warning,
                  ),
                ),
              ] else if (deadlineDays == 0) ...[
                const SizedBox(height: 8),
                const Text(
                  '今日截止',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  '已过期',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
