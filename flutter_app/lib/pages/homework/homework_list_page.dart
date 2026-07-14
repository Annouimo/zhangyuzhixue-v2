import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../../app_theme.dart';
import '../../data/daos/assignment_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/assignment_repository.dart';
import '../../data/prefs/app_prefs.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/shared/empty_placeholder.dart';
import 'widgets/assignment_card.dart';
import '../../data/debug/audit_logger.dart';

/// 作业列表页（作业 Tab 首页）
class HomeworkListPage extends StatefulWidget {
  final AssignmentRepository? assignmentRepository;

  const HomeworkListPage({super.key, this.assignmentRepository});

  @override
  State<HomeworkListPage> createState() => _HomeworkListPageState();
}

class _HomeworkListPageState extends State<HomeworkListPage> {
  late final AssignmentRepository _repo;
  List<AssignmentSummary>? _assignments;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.assignmentRepository ??
        AssignmentRepository(
          AssignmentDao(DatabaseProvider().lecturesDb),
          ProgressDao(DatabaseProvider().appDb),
          QuestionDao(DatabaseProvider().assetsDb),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 先读本地（秒开），再后台刷 API 获取截止时间等实时信息
      final list = await _repo.getPendingLocal();
      if (!mounted) return;
      AppPrefs().setPendingHomeworkCount(list.length);
      setState(() {
        _assignments = list;
        _loading = false;
      });
      AuditLogger.instance.page('HomeworkListPage', {'total': _assignments?.length});
      // 后台静默刷新
      _refreshFromApi();
    } catch (e) {
      AuditLogger.instance.error('HomeworkListPage._load', e);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final list = await _repo.getPending();
      if (!mounted) return;
      AppPrefs().setPendingHomeworkCount(list.length);
      setState(() => _assignments = list);
    } catch (_) {
      // API 失败静默忽略，已有本地数据兜底
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待办作业')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载作业…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_assignments == null || _assignments!.isEmpty) {
      return const EmptyPlaceholder(icon: Icons.assignment,
        message: '暂无待办作业',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _assignments!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final a = _assignments![index];
          return AssignmentCard(
            title: a.title,
            courseName: a.courseName,
            doneCount: a.doneCount,
            totalCount: a.totalCount,
            deadlineDays: a.deadlineDays,
            status: a.status,
            onTap: () => context.push('${AppRoutes.homeworkDetail}?id=${a.id}'),
          );
        },
      ),
    );
  }
}

