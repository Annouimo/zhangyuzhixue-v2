import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/assignment_repository.dart';

/// 作业列表页
class AssignmentListPage extends StatefulWidget {
  const AssignmentListPage({super.key});

  @override
  State<AssignmentListPage> createState() => _AssignmentListPageState();
}

class _AssignmentListPageState extends State<AssignmentListPage> {
  List<Map<String, dynamic>>? _assignments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AssignmentRepository.getPendingAssignments();
    setState(() => _assignments = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _assignments == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('待办作业', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  ..._assignments!.map((a) => Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppTheme.paddingMedium),
                      title: Text(a['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTheme.fontSizeTitle)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('完成 ${a['progress'] ?? ''}', style: const TextStyle(color: AppTheme.primaryColor)),
                            const SizedBox(height: 4),
                            Text('所属课程：${a['course'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                            Text('还有 ${a['days_left'] ?? 0} 天截止', style: const TextStyle(color: AppTheme.statusOrange, fontSize: AppTheme.fontSizeSmall)),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/assignment-questions?id=${a['id'] ?? 1}'),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}
