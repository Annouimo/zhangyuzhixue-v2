import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/question_repository.dart';
import '../widgets/filter_panel.dart';
import '../widgets/question_tile.dart';
import '../repositories/exam_repository.dart';

/// 自主组卷页
class ExamBuilderPage extends StatefulWidget {
  const ExamBuilderPage({super.key});

  @override
  State<ExamBuilderPage> createState() => _ExamBuilderPageState();
}

class _ExamBuilderPageState extends State<ExamBuilderPage> {
  final _nameController = TextEditingController();
  List<Map<String, dynamic>>? _questions;
  final Set<int> _selectedIds = {};
  Map<String, dynamic>? _filterOptions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final opts = await QuestionRepository.getFilterOptions();
    final qs = await QuestionRepository.searchQuestions();
    setState(() {
      _filterOptions = opts;
      _questions = qs;
    });
  }

  Future<void> _confirmCreate() async {
    await ExamRepository.confirmCreateExam(
      context,
      _nameController.text.isEmpty ? '未命名试卷' : _nameController.text,
      _selectedIds.toList(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自主组卷')),
      body: _questions == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              children: [
                // 筛选
                if (_filterOptions != null)
                  FilterPanel(options: _filterOptions!, onChanged: (_) {}),
                const SizedBox(height: 12),
                // 试卷名称
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '试卷名称', prefixIcon: Icon(Icons.edit_outlined)),
                ),
                const SizedBox(height: 8),
                // 已选计数
                Row(
                  children: [
                    Text('已选 ${_selectedIds.length} 题', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('积分余额：10', style: const TextStyle(color: AppTheme.accentColor)),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectedIds.isEmpty ? null : _confirmCreate,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                      child: const Text('确认组卷（10 积分）'),
                    ),
                  ],
                ),
                const Divider(),
                // 题目列表
                const Text('选题', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSizeTitle)),
                const SizedBox(height: 8),
                ...List.generate(_questions!.length, (i) {
                  final q = _questions![i];
                  return QuestionTile(
                    question: q,
                    isSelected: _selectedIds.contains(q['id']),
                    onToggle: () => setState(() {
                      if (_selectedIds.contains(q['id'])) {
                        _selectedIds.remove(q['id']);
                      } else {
                        _selectedIds.add(q['id'] as int);
                      }
                    }),
                  );
                }),
              ],
            ),
    );
  }
}
