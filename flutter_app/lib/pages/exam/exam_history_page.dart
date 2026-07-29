import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../widgets/shared/action_chip.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';
import 'widgets/paper_card.dart';

/// 我的组卷列表。
class ExamHistoryPage extends StatefulWidget {
  const ExamHistoryPage({super.key, this.examRepository});

  final ExamRepository? examRepository;

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<ExamSummary>>> _loadKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo =
        widget.examRepository ??
        ExamRepository(
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
  }

  Future<void> _deleteExam(int examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(AppIcons.delete, color: context.colors.error),
        title: const Text('删除这份试卷？'),
        content: const Text('删除后无法恢复，已经下载的 PDF 不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除', style: TextStyle(color: context.colors.error)),
          ),
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
    appBar: AppBar(title: const Text('我的试卷')),
    body: AsyncLoadWidget<List<ExamSummary>>(
      contentIsScrollable: true,
      key: _loadKey,
      onLoad: _repo.getMyExams,
      emptyWidget: EmptyPlaceholder(
        icon: Icons.description_outlined,
        message: '还没有创建过试卷，前往题库与组卷创建吧',
      ),
      builder: (ctx, list) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamHistoryPage', {'total': list.length});
        });
        return AppContentContainer(
          maxWidth: AppContentWidth.standard,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppSectionHeader(
                    title: '共 ${list.length} 份试卷',
                    subtitle: '可以切换公开状态、打印试卷、查看答案或删除。',
                  ),
                );
              }
              final exam = list[index - 1];
              return PaperCard(
                title: exam.name,
                subtitle: '创建于 ${_formatTime(exam.createdAt)}',
                trailingWidget: AppStatusBadge(
                  label: exam.isPublic ? '公开' : '私密',
                  tone: exam.isPublic
                      ? AppStatusTone.success
                      : AppStatusTone.neutral,
                  icon: exam.isPublic ? Icons.public : Icons.lock_outline,
                  compact: true,
                ),
                onTap: () => RouterUtils.push(
                  context,
                  '${AppRoutes.examQuicklook}?id=${exam.id}',
                ),
                actions: [
                  ActionChipWidget(
                    icon: exam.isPublic ? Icons.lock_outline : Icons.public,
                    label: exam.isPublic ? '设为私密' : '公开分享',
                    onTap: () async {
                      await _repo.togglePublic(exam.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('公开状态已更新')),
                        );
                      }
                      _loadKey.currentState?.refresh();
                    },
                  ),
                  ActionChipWidget(
                    icon: Icons.picture_as_pdf_outlined,
                    label: '打印试卷',
                    onTap: () => PdfHelper.downloadPdf(
                      sourceId: exam.id,
                      sourceType: 'paper',
                      context: context,
                    ),
                  ),
                  ActionChipWidget(
                    icon: Icons.fact_check_outlined,
                    iconColor: context.colors.success,
                    label: '快速对答案',
                    onTap: () => RouterUtils.push(
                      context,
                      '${AppRoutes.answerSheet}?id=${exam.id}',
                    ),
                  ),
                  ActionChipWidget(
                    icon: AppIcons.delete,
                    iconColor: context.colors.error,
                    label: '删除',
                    onTap: () => _deleteExam(exam.id),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
