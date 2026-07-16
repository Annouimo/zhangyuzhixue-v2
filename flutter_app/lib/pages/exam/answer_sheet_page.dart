import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/md_latex_body.dart';
import '../../data/debug/audit_logger.dart';
import '../../data/debug/operation_log.dart';

/// 快对答案
class AnswerSheetPage extends StatefulWidget {
  final int examId;
  final ExamRepository? examRepository;
  const AnswerSheetPage({super.key, required this.examId, this.examRepository});

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
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final preview = await _repo.getPreview(widget.examId);
      final l = await _repo.getQuickAnswers(widget.examId);
      if (!mounted) return;
      setState(() {
        _answers = l;
        _examName = preview.name;
        _totalCount = preview.totalCount;
        _loading = false;
      });
      AuditLogger.instance.page('AnswerSheetPage', {'total': _answers?.length});
    } catch (e) {
      OperationLog.instance.error('answer_sheet_page_load', e);
      AuditLogger.instance.error('AnswerSheetPage._load', e);
      if (!mounted) return;
      setState(() { _error = '加载失败，请稍后重试'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('快对答案')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载答案…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    final items = _answers ?? [];
    if (items.isEmpty) return const Center(child: Text('暂无答案'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeader(),
        ...List.generate(items.length, (i) => _buildItem(items[i], i)),
        const SizedBox(height: 12),
        _buildBackButton(),
      ],
    );
  }

  Widget _buildHeader() {
    if (_examName == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_examName!,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('共 $_totalCount 题 · 仅展示答案，无解析',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(AnswerItem a, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${index + 1}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(a.questionType,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: MdLatexBody(a.answer, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('← 返回试卷预览'),
      ),
    );
  }
}
