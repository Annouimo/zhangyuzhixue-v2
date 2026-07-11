import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';

class PointsPage extends StatefulWidget {
  final UserRepository? userRepository;
  const PointsPage({super.key, this.userRepository});

  @override State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  late final UserRepository _repo;
  List<PointsRecord>? _records;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb));
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getPointsHistory();
      if (!mounted) return;
      setState(() { _records = list; _loading = false; });
    } catch (e) {
      debugPrint('_load error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('积分流水')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            itemCount: (_records?.length ?? 0) + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              if (i == 0) {
                if (_records != null && _records!.isNotEmpty) {
                  final r = _records!.first;
                  return Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: Text('可用积分: ${r.available.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
                }
                return const SizedBox.shrink();
              }
              final r = _records![i - 1];
              return ListTile(
                title: Text(r.type, style: const TextStyle(fontSize: 14)),
                subtitle: Text(r.time.substring(0, 10), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                trailing: Text('${r.change >= 0 ? '+' : ''}${r.change.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: r.change >= 0 ? AppColors.success : AppColors.error)),
              );
            },
          ),
  );
}
