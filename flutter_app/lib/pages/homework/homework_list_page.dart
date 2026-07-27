import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/assignment_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/prefs/app_prefs.dart';
import '../../domain/assignment_repository.dart';
import '../router.dart';
import 'widgets/assignment_card.dart';

/// 待办作业列表。
class HomeworkListPage extends StatefulWidget {
  const HomeworkListPage({super.key, this.assignmentRepository});

  final AssignmentRepository? assignmentRepository;

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
          AssignmentDao(DatabaseProvider()),
          ProgressDao(DatabaseProvider()),
          QuestionDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cached = await _repo.getPendingCached();
      if (cached != null) {
        if (!mounted) return;
        AppPrefs().setPendingHomeworkCount(cached.length);
        setState(() {
          _assignments = cached;
          _loading = false;
        });
        AuditLogger.instance.page(
          'HomeworkListPage',
          {'total': _assignments?.length, 'source': 'cache'},
        );
        _refreshFromApi();
      } else {
        final list = await _repo.getPending();
        if (!mounted) return;
        AppPrefs().setPendingHomeworkCount(list.length);
        setState(() {
          _assignments = list;
          _loading = false;
        });
        AuditLogger.instance.page(
          'HomeworkListPage',
          {'total': _assignments?.length, 'source': 'api'},
        );
      }
    } catch (error) {
      OperationLog.instance.error('homework_list_page_load', error);
      AuditLogger.instance.error('HomeworkListPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final list = await _repo.getPending();
      if (!mounted) return;
      AppPrefs().setPendingHomeworkCount(list.length);
      setState(() => _assignments = list);
    } catch (_) {
      // 已有本地数据时静默保留。
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('待办作业')),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载作业…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final assignments = _assignments ?? [];
    if (assignments.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.task_alt_rounded,
        message: '当前没有待办作业，可以先练题或阅读讲义',
      );
    }

    final dueSoon = assignments.where((item) {
      final days = item.deadlineDays;
      return days != null && days >= 0 && days <= 3;
    }).length;
    final totalQuestions = assignments.fold<int>(
      0,
      (sum, item) => sum + item.totalCount,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: AppContentContainer(
        maxWidth: AppContentWidth.standard,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: assignments.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppFeatureBanner(
                  eyebrow: '学习待办',
                  icon: Icons.assignment_turned_in_outlined,
                  title: '还有 ${assignments.length} 项作业待完成',
                  subtitle: '优先处理临近截止的任务，完成后进度会自动同步。',
                  footer: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatusBadge(
                        label: '共 $totalQuestions 题',
                        tone: AppStatusTone.info,
                        icon: Icons.format_list_numbered_rounded,
                        compact: true,
                      ),
                      AppStatusBadge(
                        label: dueSoon == 0 ? '暂无紧急任务' : '$dueSoon 项即将截止',
                        tone: dueSoon == 0
                            ? AppStatusTone.success
                            : AppStatusTone.warning,
                        icon: dueSoon == 0
                            ? Icons.check_circle_outline_rounded
                            : Icons.schedule_rounded,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              );
            }
            final assignment = assignments[index - 1];
            return AssignmentCard(
              title: assignment.title,
              courseName: assignment.courseName,
              doneCount: assignment.doneCount,
              totalCount: assignment.totalCount,
              deadlineDays: assignment.deadlineDays,
              status: assignment.status,
              onTap: () => RouterUtils.push(
                context,
                '${AppRoutes.homeworkDetail}?id=${assignment.id}',
              ),
            );
          },
        ),
      ),
    );
  }
}
