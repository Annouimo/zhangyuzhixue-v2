import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_content.dart';
import '../router.dart';

/// 快速答案表。
class AnswerSheetPage extends StatefulWidget {
  const AnswerSheetPage({
    super.key,
    this.examId,
    this.virtualPaper,
    this.examRepository,
  }) : assert(examId != null || virtualPaper != null);

  final int? examId;
  final VirtualPaperRef? virtualPaper;
  final ExamRepository? examRepository;

  @override
  State<AnswerSheetPage> createState() => _AnswerSheetPageState();
}

class _AnswerSheetPageState extends State<AnswerSheetPage> {
  late final ExamRepository _repo;
  List<AnswerItem>? _answers;
  String? _examName;
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
      final virtual = widget.virtualPaper;
      final (name, totalCount, answers) = virtual == null
          ? await _loadSavedPaper()
          : await _loadVirtualPaper(virtual);
      if (!mounted) return;
      setState(() {
        _answers = answers;
        _examName = name;
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

  Future<(String, int, List<AnswerItem>)> _loadSavedPaper() async {
    final examId = widget.examId!;
    final preview = await _repo.getPreview(examId);
    final answers = await _repo.getQuickAnswers(examId);
    return (preview.name, preview.totalCount, answers);
  }

  Future<(String, int, List<AnswerItem>)> _loadVirtualPaper(
    VirtualPaperRef paper,
  ) async {
    final dao = QuestionDao(DatabaseProvider());
    final questions = await dao.getVirtualPaperQuestions(
      year: paper.year,
      examType: paper.examType,
      region: paper.region,
    );
    final answers = <AnswerItem>[];
    const labels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'};
    for (final question in questions) {
      final subs = await dao.getSubQuestions(question.id);
      final title = '${question.number} ${question.examType} ${question.region}';
      final type = labels[question.questionType] ?? question.questionType;
      if (question.questionType == 'solution' && subs.length > 1) {
        for (var index = 0; index < subs.length; index++) {
          answers.add(
            AnswerItem(
              title: '$title (${index + 1})',
              questionType: type,
              answer: subs[index].answer ?? '',
            ),
          );
        }
      } else {
        answers.add(
          AnswerItem(
            title: title,
            questionType: type,
            answer: subs.isEmpty ? '' : (subs.first.answer ?? ''),
          ),
        );
      }
    }
    return (paper.title, questions.length, answers);
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
    return AppSectionHeader(
      title: _examName ?? '试卷答案',
    );
  }

  Widget _buildItem(AnswerItem answer, int index) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AppSection(
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
