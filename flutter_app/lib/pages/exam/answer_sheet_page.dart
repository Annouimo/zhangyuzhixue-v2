import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../router.dart';

/// 快速答案表。
class AnswerSheetPage extends StatefulWidget {
  AnswerSheetPage({super.key, required this.examId, this.examRepository});

  final int examId;
  final ExamRepository? examRepository;

  @override
  State<AnswerSheetPage> createState() => _AnswerSheetPageState();
}

class _AnswerSheetPageState extends State<AnswerSheetPage> {
  late final ExamRepository _repo;
  List<AnswerItem>? _answers;
  String? _examName;
  int _totalCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.examRepository ??
        ExamRepository(
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await _repo.getPreview(widget.examId);
      final answers = await _repo.getQuickAnswers(widget.examId);
      if (!mounted) return;
      setState(() {
        _answers = answers;
        _examName = preview.name;
        _totalCount = preview.totalCount;
        _loading = false;
      });
      AuditLogger.instance.page('AnswerSheetPage', {'total': _answers?.length});
    } catch (error) {
      OperationLog.instance.error('answer_sheet_page_load', error);
      AuditLogger.instance.error('AnswerSheetPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('快速对答案')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载答案…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final items = _answers ?? [];
    if (items.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.fact_check_outlined,
        message: '这份试卷暂时没有可展示的答案',
      );
    }

    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: items.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader();
          if (index == items.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AppButton(
                label: '返回试卷预览',
                icon: AppIcons.back,
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => safePop(context),
              ),
            );
          }
          return _buildItem(items[index - 1], index);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return AppFeatureBanner(
      eyebrow: '答案速查',
      icon: Icons.fact_check_rounded,
      title: _examName ?? '试卷答案',
      subtitle: '共 $_totalCount 题。这里只展示最终答案，完整推导和知识点请进入对应题目查看。',
      footer: const Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          AppStatusBadge(
            label: '仅展示答案',
            tone: AppStatusTone.warning,
            icon: Icons.visibility_outlined,
            compact: true,
          ),
          AppStatusBadge(
            label: '解析在题目页',
            tone: AppStatusTone.info,
            icon: Icons.menu_book_outlined,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(AnswerItem answer, int index) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.medium;
          final heading = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: textTheme.titleSmall?.copyWith(color: colors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer.title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(answer.questionType, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          );
          final value = DecoratedBox(
            decoration: BoxDecoration(
              color: colors.successContainer,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: colors.success),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: MdLatexBody(answer.answer, fontSize: 15),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: AppSpacing.sm),
                value,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: value,
              ),
            ],
          );
        },
      ),
    );
  }
}
