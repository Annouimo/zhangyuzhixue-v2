import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/status_style.dart';
import '../../data/daos/assignment_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/assignment_repository.dart';
import '../../domain/question_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 作业详情页
class HomeworkDetailPage extends StatefulWidget {
  final int assignmentId;
  final AssignmentRepository? assignmentRepository;

  HomeworkDetailPage({
    super.key,
    required this.assignmentId,
    this.assignmentRepository,
  });

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage> {
  late final AssignmentRepository _repo;
  late final QuestionRepository _qRepo;
  AssignmentDetail? _detail;
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
    _qRepo = QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
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
    } catch (e) { OperationLog.instance.error('homework_detail_page_load', e); 
      AuditLogger.instance.error('HomeworkDetailPage._load', e);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.title ?? '作业详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: '下载PDF',
            onPressed: () => PdfHelper.downloadPdf(
              sourceId: widget.assignmentId,
              sourceType: 'assignment',
              context: context,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
      final colors = context.colors;
    if (_loading) return LoadingIndicator(message: '加载作业详情…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final d = _detail;
    if (d == null) return SizedBox.shrink();

    final progress = d.totalCount > 0 ? d.doneCount / d.totalCount : 0.0;
    final pct = (progress * 100).round();

    return Column(
      children: [
        // 头部信息
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSizes.baseSpacing),
          color: colors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (d.courseName.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  d.courseName,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: colors.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation(colors.success),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '完成 $pct%',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
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
            padding: EdgeInsets.all(AppSizes.baseSpacing),
            itemCount: d.questions.length,
            separatorBuilder: (_, _) => SizedBox(height: 6),
            itemBuilder: (context, index) {
              final q = d.questions[index];
              return _QuestionTile(
                index: index + 1,
                number: q.number,
                questionType: q.questionType,
                status: q.status,
                onTap: () async {
                  final route = switch (q.questionType) {
                    'choice' => AppRoutes.solveChoice,
                    'fill' => AppRoutes.solveFill,
                    'solution' => AppRoutes.solveMap,
                    _ => AppRoutes.solveMap,
                  };
                  // 据存档状态决定 mode/attemptId
                  String mode = 'first';
                  int? attemptId;
                  if (q.status != 'pending') {
                    try {
                      final attempts = await _qRepo.getAttempts(q.id);
                      if (attempts.isNotEmpty) {
                        mode = !attempts.last.isCompleted ? 'resume' : 'review';
                        attemptId = attempts.last.id;
                      }
                    } catch (e) { OperationLog.instance.error('homework_detail_page_load', e); 
                      AuditLogger.instance.error('HomeworkDetailPage.onTap', e);
                    }
                  }
                  final currentIdx = d.questions.indexWhere((q2) => q2.id == q.id);
                  final nextId = (currentIdx >= 0 && currentIdx + 1 < d.questions.length)
                      ? d.questions[currentIdx + 1].id
                      : null;
                  await RouterUtils.push(context,
                    '$route?id=${q.id}'
                    '${mode != 'first' ? '&mode=$mode' : ''}'
                    '${attemptId != null ? '&attemptId=$attemptId' : ''}'
                    '${nextId != null ? '&next=$nextId' : ''}',
                  );
                  _load();
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
String _typeLabel(String type) => QuestionTypeLabels.of(type);

/// 状态标签样式
({String label, Color color, Color bg}) _statusStyle(String status, AppSemanticColors colors) {
  return statusStyle(status, colors);
}

/// 题目行
class _QuestionTile extends StatelessWidget {
  final int index;
  final String number;
  final String questionType;
  final String status;
  final VoidCallback onTap;

  _QuestionTile({
    required this.index,
    required this.number,
    required this.questionType,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    final isDone = status == 'completed';
    final st = _statusStyle(status, colors);
    final typeLabel = _typeLabel(questionType);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone ? colors.success : colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.isNotEmpty ? '第 $number 题' : '第 $index 题',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  st.label,
                  style: TextStyle(fontSize: 11, color: st.color, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

