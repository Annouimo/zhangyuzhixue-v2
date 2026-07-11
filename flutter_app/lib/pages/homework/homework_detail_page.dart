import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/assignment_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/assignment_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../data/debug/audit_logger.dart';

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
      final detail = await _repo.getQuestions(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      AuditLogger.instance.page('HomeworkDetailPage', {'qCount': _detail?.questions.length});
    } catch (e) {
      AuditLogger.instance.error('HomeworkDetailPage._load', e);
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
      appBar: AppBar(
        title: Text(_detail?.title ?? '作业详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: '下载PDF',
            onPressed: () => PdfHelper.downloadPdf(
              sourceId: widget.assignmentId,
              sourceType: 'assignment',
            ),
          ),
        ],
      ),
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
    final pct = (progress * 100).round();

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
                    '完成 $pct%',
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
              return _QuestionTile(
                index: index + 1,
                number: q.number,
                questionType: q.questionType,
                status: q.status,
                onTap: () {
                  final route = switch (q.questionType) {
                    'choice' => '/solve/choice',
                    'fill' => '/solve/fill',
                    'solution' => '/solve/map',
                    _ => '/solve/choice',
                  };
                  context.push('$route?id=${q.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 题型中文映射
String _typeLabel(String type) {
  switch (type) {
    case 'choice': return '选择题';
    case 'fill': return '填空题';
    case 'solution': return '解答题';
    default: return type;
  }
}

/// 状态标签
({String label, Color color, Color bg}) _statusStyle(String status) {
  switch (status) {
    case 'completed':
      return (label: '已完成', color: AppColors.success, bg: const Color(0xFFECFDF5));
    case 'in_progress':
      return (label: '进行中', color: AppColors.warning, bg: const Color(0xFFFFFBEB));
    default:
      return (label: '未做', color: AppColors.textSecondary, bg: const Color(0xFFF3F4F6));
  }
}

/// 题目行
class _QuestionTile extends StatelessWidget {
  final int index;
  final String number;
  final String questionType;
  final String status;
  final VoidCallback onTap;

  const _QuestionTile({
    required this.index,
    required this.number,
    required this.questionType,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'completed';
    final st = _statusStyle(status);
    final typeLabel = _typeLabel(questionType);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.isNotEmpty ? '第 $number 题' : '第 $index 题',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  st.label,
                  style: TextStyle(fontSize: 11, color: st.color, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
