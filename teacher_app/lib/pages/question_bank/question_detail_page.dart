import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/md_latex_body.dart';
import '../../data/database/assets_database.dart' as db;

/// 题目详情页（只读模式，无答题交互）
class QuestionDetailPage extends StatefulWidget {
  final QuestionDetail detail;
  final bool initiallySelected;

  const QuestionDetailPage({
    super.key,
    required this.detail,
    this.initiallySelected = false,
  });

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.detail.question;
    return Scaffold(
      appBar: AppBar(
        title: Text('${QuestionTypeLabels.of(q.questionType)}详情'),
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
        padding: const EdgeInsets.all(16),
        children: [
          // 完整题干
          _section('题干'),
          MdLatexBody(q.stem, fontSize: 15),
          const SizedBox(height: 16),

          // 配图（images 字段为 JSON 字符串，存储图片路径数组）
          if (q.images != null && q.images!.isNotEmpty) ...[
            _buildImages(q.images!),
            const SizedBox(height: 16),
          ],

          // 元信息
          _metaInfo(q),
          const SizedBox(height: 16),

          // 选择题选项
          if (widget.detail.choiceExt != null) ...[
            _section('选项'),
            _buildOptions(widget.detail.choiceExt!),
            const SizedBox(height: 16),
          ],

          // 小题 + 答案 + 解析
          ...widget.detail.subQuestions.map((sq) {
            final subMethods = widget.detail.methods
                .where((m) => m.subQuestionId == sq.id)
                .toList();
            return _buildSubQuestion(sq, subMethods);
          }),

          // 概念标签
          if (widget.detail.tags.isNotEmpty) ...[
            _section('概念标签'),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6, runSpacing: 4,
                children: widget.detail.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(t.name,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title,
        style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _metaInfo(db.QuestionRow q) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Wrap(
        spacing: 16, runSpacing: 6,
        children: [
          _metaItem('题型', QuestionTypeLabels.of(q.questionType)),
          if (q.difficulty != null)
            _metaItem('难度', q.difficulty!.toStringAsFixed(2)),
          if (q.calculation != null)
            _metaItem('计算量', q.calculation!.toStringAsFixed(1)),
          if (q.defaultScore != null)
            _metaItem('分值', '${q.defaultScore!.toInt()}分'),
          _metaItem('年份', '${q.year}'),
          if (q.region.isNotEmpty)
            _metaItem('地区', q.region),
          if (q.examType.isNotEmpty)
            _metaItem('考试', q.examType),
          if (q.number.isNotEmpty)
            _metaItem('题号', '第${q.number}题'),
        ],
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

  /// 解析 images JSON 并显示配图
  Widget _buildImages(String imagesJson) {
    List<String> paths;
    try {
      final decoded = const JsonDecoder().convert(imagesJson);
      paths = (decoded as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (paths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('配图'),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Column(
            children: paths.map((path) {
              final assetPath = 'assets/questions/images/$path';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('图片加载失败',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(db.ChoiceExtRow choiceExt) {
    final options = choiceExt.options;
    // options 是 JSON 字符串 {"A":"...","B":"...","C":"...","D":"..."}
    Map<String, dynamic> parsed;
    try {
      parsed = const JsonDecoder().cast<String, dynamic>().convert(options);
    } catch (_) {
      return Text(options, style: const TextStyle(fontSize: 13));
    }
    // 取答案（来自第一个子题的 answer）
    final answer = widget.detail.subQuestions.isNotEmpty
        ? widget.detail.subQuestions.first.answer ?? ''
        : '';

    return Column(
      children: parsed.entries.map((e) {
        final isCorrect = answer.toUpperCase().contains(e.key.toUpperCase());
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCorrect ? AppColors.statusCompletedBg : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCorrect ? AppColors.success : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.success : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
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

  Widget _buildSubQuestion(db.SubQuestionRow sq, List<db.SolutionMethodRow> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sq.stem != null && sq.stem!.isNotEmpty) ...[
          _section('小题 ${sq.sortOrder}'),
          MdLatexBody(sq.stem!, fontSize: 14),
          const SizedBox(height: 8),
        ],
        // 答案
        if (sq.answer != null && sq.answer!.isNotEmpty) ...[
          _section('答案'),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.statusInProgressBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: MdLatexBody(sq.answer!, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        // 解析
        if (sq.explanation != null && sq.explanation!.isNotEmpty) ...[
          _section('解析'),
          MdLatexBody(sq.explanation!, fontSize: 14),
          const SizedBox(height: 8),
        ],
        // 解法步骤
        ...methods.map((m) => _buildMethod(m)),
      ],
    );
  }

  Widget _buildMethod(db.SolutionMethodRow method) {
    final methodSteps = widget.detail.steps
        .where((s) => s.methodId == method.id)
        .toList();
    if (methodSteps.isEmpty) return const SizedBox.shrink();

    final methodName = method.methodName ?? '唯一解法';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(methodName,
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
                width: 20, height: 20,
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
