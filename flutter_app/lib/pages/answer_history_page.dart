import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/user_repository.dart';

/// 做题历史页
class AnswerHistoryPage extends StatefulWidget {
  const AnswerHistoryPage({super.key});

  @override
  State<AnswerHistoryPage> createState() => _AnswerHistoryPageState();
}

class _AnswerHistoryPageState extends State<AnswerHistoryPage> {
  List<Map<String, dynamic>>? _history;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await UserRepository.getAnswerHistory();
    setState(() => _history = data);
  }

  Color _statusColor(String? s) {
    if (s == '已完成') return AppTheme.statusGreen;
    if (s == '进行中') return AppTheme.statusOrange;
    return AppTheme.statusGray;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('做题历史')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _history == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _history!.length,
                itemBuilder: (_, i) {
                  final h = _history![i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                    child: ListTile(
                      title: Text(h['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(h['type'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(h['status']).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(h['status'] ?? '', style: TextStyle(color: _statusColor(h['status']), fontSize: AppTheme.fontSizeSmall)),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/solve?id=1'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
