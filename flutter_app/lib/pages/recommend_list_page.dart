import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/question_repository.dart';

/// 推荐题目列表页（首页"题目推荐"入口的二级页面）
class RecommendListPage extends StatefulWidget {
  const RecommendListPage({super.key});

  @override
  State<RecommendListPage> createState() => _RecommendListPageState();
}

class _RecommendListPageState extends State<RecommendListPage> {
  List<Map<String, dynamic>>? _questions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await QuestionRepository.getRecommended();
    setState(() => _questions = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('题目推荐')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _questions == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _questions!.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  if (i == _questions!.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('（点击后进入解题模式）', style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                    );
                  }
                  final q = _questions![i];
                  final status = q['status'] as String? ?? '未做';
                  Color statusColor;
                  switch (status) {
                    case '已完成': statusColor = AppTheme.statusGreen; break;
                    case '进行中': statusColor = AppTheme.statusOrange; break;
                    default: statusColor = AppTheme.statusGray;
                  }
                  return ListTile(
                    title: Text('${q['title'] ?? ''} ${q['type'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(q['course'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: AppTheme.fontSizeSmall)),
                    ),
                    onTap: () => Navigator.pushNamed(context, '/solve?id=${q['id'] ?? 1}'),
                  );
                },
              ),
      ),
    );
  }
}
