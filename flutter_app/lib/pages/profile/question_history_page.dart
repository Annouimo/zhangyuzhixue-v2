import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/question_card.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
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
    _repo = widget.userRepository ?? UserRepository(UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _repo.getAnswerHistory();
      if (!mounted) return;
      setState(() { _history = list; _loading = false; });
      AuditLogger.instance.page('QuestionHistoryPage', {'total': _history?.length});
    } catch (e) { OperationLog.instance.error('question_history_page_load', e); 
      AuditLogger.instance.error('QuestionHistoryPage._load', e);
      if (mounted) setState(() { _error = '加载失败，请稍后重试'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('做题历史')),
    body: _loading ? const LoadingIndicator()
      : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : _history == null || _history!.isEmpty
        ? Center(child: Text('暂无做题记录', style: TextStyle(color: context.colors.textSecondary)))
        : ListView.separated(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            itemCount: _history!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final h = _history![i];
              return QuestionCard(
                questionId: h.questionId,
                title: h.title,
                questionType: h.questionType,
                subtitle: h.date,
                status: h.status,
                onTap: () {
                  final route = switch (h.questionType) {
                    'choice' => AppRoutes.solveChoice,
                    'fill' => AppRoutes.solveFill,
                    'solution' => AppRoutes.solveMap,
                    _ => AppRoutes.solveMap,
                  };
                  final mode = h.isCompleted ? 'review' : 'resume';
                  RouterUtils.push(context,
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

