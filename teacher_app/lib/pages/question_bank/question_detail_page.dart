import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../domain/question_repository.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/widgets/question_image.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../../data/database/assets_database.dart' as db;

/// 题目详情页（只读模式，无答题交互）
///
/// 接收 questionId + repo，内部异步加载，先显示 LoadingIndicator
/// 避免 Navigator.push 过渡动画因首帧 build 过重而掉帧。
class QuestionDetailPage extends StatefulWidget {
  final int questionId;
  final QuestionRepository repo;
  final bool initiallySelected;

  const QuestionDetailPage({
    super.key,
    required this.questionId,
    required this.repo,
    this.initiallySelected = false,
  });

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  QuestionDetail? _detail;
  bool _loading = true;
  String? _error;
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await widget.repo.getQuestionDetail(widget.questionId);
      if (!mounted) return;
      setState(() { _detail = detail; _loading = false; });
      AuditLogger.instance.page('QuestionDetailPage', {
        'questionId': widget.questionId, 'choiceExt': detail.choiceExt != null,
        'subQuestions': detail.subQuestions.length, 'methods': detail.methods.length,
        'steps': detail.steps.length, 'tags': detail.tags.length,
      });
    } catch (e) {
      AuditLogger.instance.error('QuestionDetailPage._load', e);
      OperationLog.instance.error('QuestionDetailPage._load', e);
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('题目详情')),
        body: const LoadingIndicator(message: '加载题目详情…'),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('题目详情')),
        body: ErrorPlaceholder(message: _error!, onRetry: _load),
      );
    }

    final q = _detail!.question;
    return Scaffold(
      appBar: AppBar(
        title: Text(q.number.isNotEmpty
            ? '第${q.number}题（${QuestionTypeLabels.of(q.questionType)}）'
            : '题目详情'),
        actions: [
          IconButton(
            icon: Icon(
              _selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _selected ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _selected = !_selected),
            tooltip: _selected ? '取消勾选' : '勾选此题',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        children: [
          // 概念标签
          if (_detail!.tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6, runSpacing: 4,
                children: _detail!.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t.name,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                )).toList(),
              ),
            ),
          ],

          // 完整题干
          _section('题干'),
          MdLatexBody(q.stem, fontSize: 15),
          const SizedBox(height: 16),

          // 配图
          if (q.images != null && q.images!.isNotEmpty) ...[
            _section('配图'),
            ..._parseImagePaths(q.images!).map((path) =>
              QuestionImage(relativePath: path),
            ),
            const SizedBox(height: 16),
          ],

          // 元信息
          _metaInfo(q),
          const SizedBox(height: 16),

          // 选择题选项
          if (_detail!.choiceExt != null) ...[
            _section('选项'),
            _buildOptions(_detail!.choiceExt!),
            const SizedBox(height: 16),
          ],

          // 小题 + 答案 + 解析
          ..._detail!.subQuestions.map((sq) {
            final subMethods = _detail!.methods
                .where((m) => m.subQuestionId == sq.id)
                .toList();
            final isChoice = _detail!.choiceExt != null;
            return _buildSubQuestion(sq, subMethods, hideAnswer: isChoice);
          }),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Text(title,
        style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _metaInfo(db.QuestionRow q) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16, runSpacing: 6,
          children: [
            _metaItem('题型', QuestionTypeLabels.of(q.questionType)),
            if (q.difficulty != null)
              _metaItem('难度', '${q.difficulty!.toStringAsFixed(1)} / 10'),
            if (q.calculation != null)
              _metaItem('计算量', '${q.calculation!.toStringAsFixed(1)} / 10'),
            if (q.defaultScore != null)
              _metaItem('分值', '${q.defaultScore!.toInt()}分'),
            _metaItem('年份', '${q.year}'),
            if (q.region.isNotEmpty)
              _metaItem('地区', q.region),
            if (q.examType.isNotEmpty)
              _metaItem('考试', q.examType),
            if (q.number.isNotEmpty)
              _metaItem('题号', '第${q.number}题'),
            Text('ID: ${_detail!.question.id}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }

  void _showKnowledgeCard(db.KnowledgeCardRow kc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${kc.category} · ${kc.title}'),
        content: SingleChildScrollView(
          child: MdLatexBody(kc.content, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _buildStepKnowledgeCards(String cardTitlesJson, Map<String, db.KnowledgeCardRow> kcMap) {
    List<String> titles;
    try {
      titles = (const JsonDecoder().convert(cardTitlesJson) as List)
          .map((e) => e.toString()).toList();
    } catch (_) {
      return const SizedBox.shrink();
    }
    final matched = titles.map((t) => kcMap[t]).where((kc) => kc != null).cast<db.KnowledgeCardRow>().toList();
    if (matched.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4, runSpacing: 2,
        children: matched.map((kc) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _showKnowledgeCard(kc),
            child: Text('${kc.category}·${kc.title}',
              style: const TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _accentContainer(String title, Color accentColor, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3, height: 18,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  List<String> _parseImagePaths(String imagesJson) {
    try {
      final decoded = const JsonDecoder().convert(imagesJson);
      return (decoded as List)
          .map((e) => e.toString().replaceAll('\\', '/'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Widget _buildOptions(db.ChoiceExtRow choiceExt) {
    final options = choiceExt.options;
    Map<String, dynamic> parsed;
    try {
      parsed = const JsonDecoder().cast<String, dynamic>().convert(options);
    } catch (_) {
      return Text(options, style: const TextStyle(fontSize: 13));
    }
    final answer = _detail!.subQuestions.isNotEmpty
        ? _detail!.subQuestions.first.answer ?? ''
        : '';

    return Column(
      children: parsed.entries.map((e) {
        final isCorrect = answer.toUpperCase().contains(e.key.toUpperCase());
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCorrect ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(
              color: isCorrect ? AppColors.success : AppColors.border,
              width: isCorrect ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.success : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(e.key,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isCorrect ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MdLatexBody(e.value.toString(), fontSize: 14),
              ),
              if (isCorrect)
                const Icon(Icons.check, size: 16, color: AppColors.success),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubQuestion(db.SubQuestionRow sq, List<db.SolutionMethodRow> methods, {bool hideAnswer = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sq.stem != null && sq.stem!.isNotEmpty) ...[
          _section('小题 ${sq.sortOrder}'),
          MdLatexBody(sq.stem!, fontSize: 14),
          const SizedBox(height: 8),
        ],
        if (!hideAnswer && sq.answer != null && sq.answer!.isNotEmpty) ...[
          _section('答案'),
          _accentContainer('答案', AppColors.success, MdLatexBody(sq.answer!, fontSize: 14)),
        ],
        if (sq.explanation != null && sq.explanation!.isNotEmpty) ...[
          _section('解析'),
          _accentContainer('解析', AppColors.primary, MdLatexBody(sq.explanation!, fontSize: 14)),
        ],
        ...methods.map((m) => _buildMethod(m)),
      ],
    );
  }

  Widget _buildMethod(db.SolutionMethodRow method) {
    final methodSteps = _detail!.steps
        .where((s) => s.methodId == method.id)
        .toList();
    if (methodSteps.isEmpty) return const SizedBox.shrink();

    final kcMap = {for (final kc in _detail!.knowledgeCards) kc.title: kc};
    final hasMultipleMethods = _detail!.methods.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMultipleMethods)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(method.methodName ?? '解法${method.id}',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ...methodSteps.map((step) => Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${step.stepNumber}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step.title.isNotEmpty)
                      Text(step.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    if (step.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: MdLatexBody(step.content, fontSize: 13),
                      ),
                    if (step.cardTitles != null && step.cardTitles!.isNotEmpty)
                      _buildStepKnowledgeCards(step.cardTitles!, kcMap),
                  ],
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

