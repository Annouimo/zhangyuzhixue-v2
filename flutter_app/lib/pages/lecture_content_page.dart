import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/lecture_repository.dart';

/// 讲义正文页（含翻页）
class LectureContentPage extends StatefulWidget {
  final int chapterId;

  const LectureContentPage({super.key, required this.chapterId});

  @override
  State<LectureContentPage> createState() => _LectureContentPageState();
}

class _LectureContentPageState extends State<LectureContentPage> {
  Map<String, dynamic>? _lecture;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LectureRepository.getLectureContent(widget.chapterId);
    setState(() {
      _lecture = data;
      _currentPage = data['current_page'] ?? 1;
    });
  }

  void _prevPage() {
    if (_currentPage > 1) setState(() => _currentPage--);
  }

  void _nextPage() {
    if (_lecture != null && _currentPage < (_lecture!['total_pages'] ?? 1)) {
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_lecture?['title'] ?? '讲义')),
      body: _lecture == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Text(
                      '${_lecture!['content']}\n\n（第 $_currentPage 页）',
                      style: const TextStyle(fontSize: AppTheme.fontSizeBody, height: 1.8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.dividerColor))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(onPressed: _prevPage, icon: const Icon(Icons.chevron_left), label: const Text('上一页')),
                      Text('第 $_currentPage/${_lecture!['total_pages']} 页', style: const TextStyle(color: AppTheme.textSecondary)),
                      TextButton.icon(onPressed: _nextPage, icon: const Icon(Icons.chevron_right), label: const Text('下一页')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
