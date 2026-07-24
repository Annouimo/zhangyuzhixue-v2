import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../../widgets/shared/async_load_widget.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import '../../../data/helpers/pdf_helper.dart';
import 'widgets/paper_card.dart';
import 'package:shared/debug/audit_logger.dart';

/// 我的组卷列表 — 匹配 HTML 原型 paper_history.html
class ExamHistoryPage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamHistoryPage({super.key, this.examRepository});

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<ExamSummary>>> _loadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
    );
  }

  Future<void> _deleteExam(int examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此组卷吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: context.colors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteExam(examId);
      _loadKey.currentState?.refresh();
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
    body: AsyncLoadWidget<List<ExamSummary>>(
      key: _loadKey,
      onLoad: () => _repo.getMyExams(),
      emptyWidget: const EmptyPlaceholder(
        icon: Icons.assignment,
        message: '还没有创建过试卷，去首页试试快速练习吧',
      ),
      builder: (ctx, list) {
        // 构建后记录审计日志
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamHistoryPage', {'total': list.length});
        });
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.baseSpacing),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final e = list[i];
            return PaperCard(
              title: e.name,
              subtitle: '创建于 ${_formatTime(e.createdAt)}',
              onTap: () => context.push('${AppRoutes.examQuicklook}?id=${e.id}'),
              actions: [
                IconButton(
                  icon: Icon(e.isPublic ? Icons.public : Icons.lock, size: 18),
                  tooltip: e.isPublic ? '公开' : '私密',
                  onPressed: () async {
                    await _repo.togglePublic(e.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('公开状态已切换'), behavior: SnackBarBehavior.floating),
                      );
                    }
                    _loadKey.currentState?.refresh();
                  },
                ),
                ActionChipWidget(icon: Icons.file_download, label: 'PDF', onTap: () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context)),
                const SizedBox(width: 4),
                ActionChipWidget(icon: Icons.check_circle, iconColor: context.colors.success, label: '答案', onTap: () => context.push('${AppRoutes.answerSheet}?id=${e.id}')),
                const SizedBox(width: 4),
                ActionChipWidget(icon: Icons.delete_outline, label: '删除', onTap: () => _deleteExam(e.id)),
              ],
            );
          },
        );
      },
    ),
  );
}
