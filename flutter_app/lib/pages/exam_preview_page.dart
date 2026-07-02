import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/exam_repository.dart';

/// 快对答案 / 试卷预览页
class ExamPreviewPage extends StatefulWidget {
  final int examId;

  const ExamPreviewPage({super.key, required this.examId});

  @override
  State<ExamPreviewPage> createState() => _ExamPreviewPageState();
}

class _ExamPreviewPageState extends State<ExamPreviewPage> {
  List<Map<String, dynamic>>? _exams;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ExamRepository.getMyExams();
    setState(() => _exams = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的试卷')),
      body: _exams == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              itemCount: _exams!.length,
              itemBuilder: (_, i) {
                final e = _exams![i];
                final qs = e['questions'] as List? ?? [];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSizeTitle)),
                        const SizedBox(height: 4),
                        Text(
                          '选择 ${e['choice_count'] ?? 0} 题  填空 ${e['fill_count'] ?? 0} 题  解答 ${e['solution_count'] ?? 0} 题  共 ${e['total'] ?? 0} 题',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(qs.length, (j) {
                          final q = qs[j];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('· ${q['source'] ?? ''}  难度 ${q['difficulty'] ?? ''}  计算量 ${q['calculation'] ?? ''}',
                              style: const TextStyle(fontSize: AppTheme.fontSizeSmall)),
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () {}, child: const Text('下载 PDF')),
                            const SizedBox(width: 8),
                            TextButton(onPressed: () {}, child: const Text('快对答案')),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => ExamRepository.deleteExam(context, i).then((_) => _load()),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
