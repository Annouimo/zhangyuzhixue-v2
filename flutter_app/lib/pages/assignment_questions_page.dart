import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/assignment_repository.dart';

/// 作业内题目列表页（点击作业条目后进入）
class AssignmentQuestionsPage extends StatefulWidget {
  final int assignmentId;

  const AssignmentQuestionsPage({super.key, required this.assignmentId});

  @override
  State<AssignmentQuestionsPage> createState() => _AssignmentQuestionsPageState();
}

class _AssignmentQuestionsPageState extends State<AssignmentQuestionsPage> {
  List<Map<String, dynamic>>? _questions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AssignmentRepository.getAssignmentQuestions(widget.assignmentId);
    setState(() => _questions = data);
  }

  Color _statusColor(String? s) {
    switch (s) {
      case '已完成': return AppTheme.statusGreen;
      case '进行中': return AppTheme.statusOrange;
      default: return AppTheme.statusGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导数第 1 讲课后练习')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _questions == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _questions!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final q = _questions![i];
                  final status = q['status'] as String? ?? '未做';
                  return ListTile(
                    title: Text('${q['number'] ?? ''} ${q['type'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: AppTheme.fontSizeSmall)),
                    ),
                    onTap: () => Navigator.pushNamed(context, '/solve?id=${q['id'] ?? 1}'),
                  );
                },
              ),
      ),
    );
  }
}
