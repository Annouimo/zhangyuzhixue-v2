import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/user_repository.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>>? _recommended;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserRepository.getUserInfo();
    // 首页的题目推荐用 question repo，但先临时用 user repo 的结果作为占位演示
    // 实际应调用 QuestionRepository.getRecommended()
    setState(() {
      _user = user;
      _recommended = [
        {'title': '2025 海淀一模 Q20', 'type': '解答题', 'course': '导数系统课', 'status': '进行中'},
        {'title': '2025 东城一模 Q6', 'type': '解答题', 'course': '公益讲座', 'status': '未做'},
        {'title': '2025 西城一模 Q15', 'type': '填空题', 'course': '导数系统课', 'status': '未做'},
      ];
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? '...';
    return Scaffold(
      appBar: AppBar(title: Text('$_greeting，$name')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          children: [
            // 自主组卷入
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/exam-builder'),
                icon: const Icon(Icons.auto_stories),
                label: const Text('自主组卷'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            const Text('题目推荐', style: TextStyle(fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.paddingSmall),
            if (_recommended == null)
              const Center(child: CircularProgressIndicator())
            else if (_recommended!.isEmpty)
              const Center(child: Text('暂无推荐题目', style: TextStyle(color: AppTheme.textSecondary)))
            else
              ...List.generate(_recommended!.length, (i) {
                final q = _recommended![i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    title: Text(q['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(q['course'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (q['status'] == '已完成' ? AppTheme.statusGreen : q['status'] == '进行中' ? AppTheme.statusOrange : AppTheme.statusGray).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(q['status'] ?? '', style: TextStyle(
                        color: q['status'] == '已完成' ? AppTheme.statusGreen : q['status'] == '进行中' ? AppTheme.statusOrange : AppTheme.statusGray,
                        fontSize: AppTheme.fontSizeSmall,
                      )),
                    ),
                    onTap: () => Navigator.pushNamed(context, '/solve?id=1'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
