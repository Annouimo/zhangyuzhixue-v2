import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/daos/achievement_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/achievement_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';

/// 成就页
class AchievementPage extends StatefulWidget {
  final AchievementRepository? achievementRepository;
  const AchievementPage({super.key, this.achievementRepository});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  late final AchievementRepository _repo;
  bool _loading = true;
  String? _error;
  List<AchievementCategory>? _categories;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.achievementRepository ?? AchievementRepository(AchievementDao(db.appDb), QuestionDao(db.assetsDb), ExamDao(db.appDb));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await _repo.getCategories();
      if (!mounted) return;
      setState(() { _categories = cats; _loading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('成就')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载成就…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    final cats = _categories ?? [];
    if (cats.isEmpty) return const Center(child: Text('暂无成就', style: TextStyle(color: AppColors.textSecondary)));
    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: cats.map((cat) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...cat.list.map((a) => ListTile(
            leading: Text(a.iconEmoji, style: const TextStyle(fontSize: 28)),
            title: Text(a.name),
            subtitle: Text(a.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (a.status == 'unlocked')
                const Text('✅ 已解锁', style: TextStyle(fontSize: 11, color: AppColors.success))
              else ...[
                Text('${a.progress}/${a.threshold}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 2),
                SizedBox(width: 60, child: LinearProgressIndicator(
                  value: a.progressPercent / 100, backgroundColor: Colors.grey[200])),
              ],
            ]),
          )),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],
      )).toList(),
    );
  }
}
