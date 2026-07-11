import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/assignment_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/assignment_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';

/// 作业详情页
class HomeworkDetailPage extends StatefulWidget {
  final int assignmentId;
  final AssignmentRepository? assignmentRepository;

  const HomeworkDetailPage({
    super.key,
    required this.assignmentId,
    this.assignmentRepository,
  });

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage> {
  late final AssignmentRepository _repo;
  AssignmentDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.assignmentRepository ??
        AssignmentRepository(AssignmentDao(DatabaseProvider().lecturesDb));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repo.getQuestions(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
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
      appBar: AppBar(title: Text(_detail?.title ?? '作业详情')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载作业详情…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final d = _detail;
    if (d == null) return const SizedBox.shrink();

    final progress = d.totalCount > 0 ? d.doneCount / d.totalCount : 0.0;

    return Column(
      children: [
        // 头部信息
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.baseSpacing),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (d.courseName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  d.courseName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '完成 $progress%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 题目列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            itemCount: d.questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final q = d.questions[index];
              final isDone = q.status == 'completed';
              return _QuestionTile(
                index: index + 1,
                number: q.number,
                isDone: isDone,
                onTap: () => context.push('/solve/choice?id=${q.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 题目行
class _QuestionTile extends StatelessWidget {
  final int index;
  final String number;
  final bool isDone;
  final VoidCallback onTap;

  const _QuestionTile({
    required this.index,
    required this.number,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.success : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  number.isNotEmpty ? '第 $number 题' : '第 $index 题',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
