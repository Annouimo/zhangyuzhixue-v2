import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/empty_placeholder.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../../data/helpers/pdf_helper.dart';
import 'widgets/paper_card.dart';
import '../../data/debug/audit_logger.dart';
import '../../data/debug/operation_log.dart';
import '../../../data/debug/operation_log.dart';

/// 我的组卷列表 — 匹配 HTML 原型 paper_history.html
class ExamHistoryPage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamHistoryPage({super.key, this.examRepository});

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamRepository _repo;
  List<ExamSummary>? _list;
  bool _loading = true; String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final l = await _repo.getMyExams();
      if (!mounted) return;
      setState(() { _list = l; _loading = false; });
      AuditLogger.instance.page('ExamHistoryPage', {'total': _list?.length});
    } catch (e) { OperationLog.instance.error('exam_history_page_load', e);  AuditLogger.instance.error('ExamHistoryPage._load', e); if (!mounted) return; setState(() { _error = '加载失败，请稍后重试'; _loading = false; }); }
  }

  Future<void> _deleteExam(int examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此组卷吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteExam(examId);
      _load();
    }
  }

  String _formatTime(String iso) {
    try {
      return iso.substring(0, 16).replaceFirst('T', ' ');
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的组卷')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载组卷…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    if (_list == null || _list!.isEmpty) return const EmptyPlaceholder(icon: Icons.assignment, message: '还没有创建过试卷，去首页试试快速练习吧');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _list!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final e = _list![i];
          return PaperCard(
            title: e.name,
            subtitle: '创建于 ${_formatTime(e.createdAt)}',
            onTap: () => context.push('${AppRoutes.examQuicklook}?id=${e.id}'),
            actions: [
              IconButton(
                icon: Icon(e.isPublic ? Icons.public : Icons.lock, size: 18),
                tooltip: e.isPublic ? '公开' : '私密',
                onPressed: () async { await _repo.togglePublic(e.id); _load(); },
              ),
              ActionChipWidget(icon: Icons.file_download, label: 'PDF', onTap: () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context)),
              const SizedBox(width: 4),
              ActionChipWidget(icon: Icons.check_circle, iconColor: Colors.green, label: '答案', onTap: () => context.push('${AppRoutes.answerSheet}?id=${e.id}')),
              const SizedBox(width: 4),
              ActionChipWidget(icon: Icons.delete_outline, label: '删除', onTap: () => _deleteExam(e.id)),
            ],
          );
        },
      ),
    );
  }
}


