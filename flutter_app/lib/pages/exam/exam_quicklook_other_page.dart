import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/helpers/pdf_helper.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/md_latex_body.dart';
import '../../data/debug/audit_logger.dart';

/// 预览（他人的组卷）
class ExamQuicklookOtherPage extends StatefulWidget {
  final int examId;
  final ExamRepository? examRepository;
  const ExamQuicklookOtherPage({super.key, required this.examId, this.examRepository});

  @override
  State<ExamQuicklookOtherPage> createState() => _ExamQuicklookOtherPageState();
}

class _ExamQuicklookOtherPageState extends State<ExamQuicklookOtherPage> {
  late final ExamRepository _repo;
  ExamPreviewOther? _preview;
  bool _loading = true; String? _error;
  bool _liked = false, _collected = false;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(db.assetsDb), ExamDao(db.appDb),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.getPreviewOther(widget.examId);
      if (!mounted) return;
      setState(() { _preview = p; _liked = p.likeCount > 0; _collected = p.collectCount > 0; _loading = false; });
      AuditLogger.instance.page('ExamQuicklookOtherPage', {'title': _preview?.name});
    } catch (e) { AuditLogger.instance.error('ExamQuicklookOtherPage._load', e); if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_preview?.name ?? '预览'),
      actions: [
        IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: '下载PDF',
          onPressed: () => PdfHelper.downloadPdf(sourceId: widget.examId, sourceType: 'paper')),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载预览…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    final p = _preview;
    if (p == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: [
        Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('共 ${p.totalCount} 题 · 选择 ${p.choiceCount} 填空 ${p.fillCount} 解答 ${p.solutionCount}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(children: [
          _actionChip(Icons.thumb_up_alt_outlined, '${p.likeCount}', _liked, () => _toggleLike()),
          const SizedBox(width: 8),
          _actionChip(Icons.bookmark_border, '${p.collectCount}', _collected, () => _toggleCollect()),
        ]),
        const SizedBox(height: 16),
        ...p.questions.map((q) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(child: Padding(padding: const EdgeInsets.all(12), child: MdLatexBody(q.title, fontSize: 14))),
        )),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label, bool active, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textSecondary),
      label: Text(label, style: TextStyle(fontSize: 12, color: active ? AppColors.primary : AppColors.textSecondary)),
      onPressed: onTap,
      backgroundColor: active ? AppColors.primaryLight : Colors.grey[100],
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _toggleLike() async {
    await _repo.toggleLike(widget.examId);
    setState(() => _liked = !_liked);
  }

  Future<void> _toggleCollect() async {
    await _repo.toggleCollect(widget.examId);
    setState(() => _collected = !_collected);
  }
}
