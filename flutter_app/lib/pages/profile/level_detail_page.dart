import 'package:flutter/material.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../data/debug/audit_logger.dart';

class LevelDetailPage extends StatefulWidget {
  final UserRepository? userRepository;
  const LevelDetailPage({super.key, this.userRepository});

  @override State<LevelDetailPage> createState() => _LevelDetailPageState();
}

class _LevelDetailPageState extends State<LevelDetailPage> {
  late final UserRepository _repo;
  String _progress = '0/0';
  int _earned = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.levelProgress();
      final e = await _repo.earnedPoints();
      if (!mounted) return;
      setState(() { _progress = p; _earned = e.toInt(); _loading = false; });
      AuditLogger.instance.page('LevelDetailPage', {'progress': _progress, 'earned': _earned});
    } catch (e) {
      AuditLogger.instance.error('LevelDetailPage._load', e);
      debugPrint('_load error: $e');
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('等级进度')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ErrorPlaceholder(message: _error!, onRetry: _load)
            : Padding(padding: const EdgeInsets.all(AppSizes.baseSpacing), child: Column(children: [
      const CircleAvatar(radius: 40, backgroundColor: AppColors.primaryLight, child: Icon(Icons.trending_up, size: 40, color: AppColors.primary)),
      const SizedBox(height: 12),
      Text('经验值: $_earned', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: _parseProgress(_progress), backgroundColor: Colors.grey[200]),
      const SizedBox(height: 8),
      Text('进度: $_progress', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ])),
  );

  double _parseProgress(String p) {
    final parts = p.split('/');
    if (parts.length != 2) return 0;
    final num = double.tryParse(parts[0]) ?? 0;
    final den = double.tryParse(parts[1]) ?? 1;
    return den > 0 ? (num / den).clamp(0.0, 1.0) : 0;
  }
}
