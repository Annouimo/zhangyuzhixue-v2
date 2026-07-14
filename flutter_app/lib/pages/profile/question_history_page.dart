import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import '../../data/debug/audit_logger.dart';
import '../router.dart';

class QuestionHistoryPage extends StatefulWidget {
  final UserRepository? userRepository;
  const QuestionHistoryPage({super.key, this.userRepository});

  @override State<QuestionHistoryPage> createState() => _QuestionHistoryPageState();
}

class _QuestionHistoryPageState extends State<QuestionHistoryPage> {
  late final UserRepository _repo;
  List<HistoryItem>? _history;
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
      final list = await _repo.getAnswerHistory();
      if (!mounted) return;
      setState(() { _history = list; _loading = false; });
      AuditLogger.instance.page('QuestionHistoryPage', {'total': _history?.length});
    } catch (e) {
      AuditLogger.instance.error('QuestionHistoryPage._load', e);
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static const _statusLabels = {'completed': '已完成', 'in_progress': '进行中'};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('做题历史')),
    body: _loading ? const LoadingIndicator()
      : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : _history == null || _history!.isEmpty
        ? const Center(child: Text('暂无做题记录', style: TextStyle(color: AppColors.textSecondary)))
        : ListView.separated(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            itemCount: _history!.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final h = _history![i];
              return ListTile(
                title: Text(h.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text('${h.questionType} · ${h.date} · ${_statusLabels[h.status] ?? h.status}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                onTap: () {
                  final route = switch (h.questionType) {
                    'choice' => AppRoutes.solveChoice,
                    'fill' => AppRoutes.solveFill,
                    'solution' => AppRoutes.solveMap,
                    _ => AppRoutes.solveChoice,
                  };
                  final mode = h.isCompleted ? 'review' : 'resume';
                  context.push(
                    '$route?id=${h.questionId}'
                    '&mode=$mode'
                    '&attemptId=${h.id}',
                  );
                },
              );
            },
          ),
  );
}
