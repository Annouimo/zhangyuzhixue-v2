import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_state_panel.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/question_card.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import '../router.dart';

class QuestionHistoryPage extends StatefulWidget {
  const QuestionHistoryPage({super.key, this.userRepository});

  final UserRepository? userRepository;

  @override
  State<QuestionHistoryPage> createState() => _QuestionHistoryPageState();
}

class _QuestionHistoryPageState extends State<QuestionHistoryPage> {
  late final UserRepository _repo;
  List<HistoryItem>? _history;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.userRepository ??
        UserRepository(
          UserDao(DatabaseProvider()),
          UserApi(ApiClient()),
          QuestionDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await _repo.getAnswerHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _loading = false;
      });
      AuditLogger.instance.page('QuestionHistoryPage', {
        'total': history.length,
      });
    } catch (error) {
      OperationLog.instance.error('question_history_page_load', error);
      AuditLogger.instance.error('QuestionHistoryPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('做题历史')),
      body: _loading
          ? const LoadingIndicator(message: '正在整理做题记录…')
          : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final history = _history ?? [];
    if (history.isEmpty) {
      return const AppStatePanel(
        title: '暂无做题记录',
        message: '开始一次推荐练习或快速练习后，进度会自动保存在这里。',
        tone: AppStateTone.empty,
        icon: Icons.history_edu_outlined,
      );
    }

    return AppContentContainer(
      maxWidth: AppContentWidth.standard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          AppSectionHeader(
            title: '最近记录',
            subtitle: '共 ${history.length} 道，点击题目继续作答或查看解析。',
          ),
          const SizedBox(height: AppSpacing.md),
          ...history.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: QuestionCard(
                questionId: item.questionId,
                title: item.title,
                questionType: item.questionType,
                subtitle: item.date,
                status: item.status,
                onTap: () => _openQuestion(item),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _openQuestion(HistoryItem item) {
    final route = switch (item.questionType) {
      'choice' => AppRoutes.solveChoice,
      'fill' => AppRoutes.solveFill,
      'solution' => AppRoutes.solveMap,
      _ => AppRoutes.solveMap,
    };
    final mode = item.isCompleted ? 'review' : 'resume';
    RouterUtils.push(
      context,
      '$route?id=${item.questionId}&mode=$mode&attemptId=${item.id}',
    );
  }
}
