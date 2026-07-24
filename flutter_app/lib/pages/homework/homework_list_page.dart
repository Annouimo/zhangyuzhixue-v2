import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/assignment_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/assignment_repository.dart';
import '../../data/prefs/app_prefs.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import 'widgets/assignment_card.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 作业列表页（作业 Tab 首页）
class HomeworkListPage extends StatefulWidget {
  final AssignmentRepository? assignmentRepository;

  HomeworkListPage({super.key, this.assignmentRepository});

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
          AssignmentDao(DatabaseProvider()),
          ProgressDao(DatabaseProvider()),
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
      // 有精确缓存则秒开，否则等 API
      final cached = await _repo.getPendingCached();
      if (cached != null) {
        if (!mounted) return;
        AppPrefs().setPendingHomeworkCount(cached.length);
        setState(() {
          _assignments = cached;
          _loading = false;
        });
        AuditLogger.instance.page('HomeworkListPage', {'total': _assignments?.length, 'source': 'cache'});
        _refreshFromApi();
      } else {
        final list = await _repo.getPending();
        if (!mounted) return;
        AppPrefs().setPendingHomeworkCount(list.length);
        setState(() {
          _assignments = list;
          _loading = false;
        });
        AuditLogger.instance.page('HomeworkListPage', {'total': _assignments?.length, 'source': 'api'});
      }
    } catch (e) { OperationLog.instance.error('homework_list_page_load', e); 
      AuditLogger.instance.error('HomeworkListPage._load', e);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
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
      appBar: AppBar(title: Text('待办作业')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return LoadingIndicator(message: '加载作业…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (_assignments == null || _assignments!.isEmpty) {
      return EmptyPlaceholder(icon: Icons.assignment,
        message: '暂无待办作业 🤔 可以先刷刷题或看看讲义',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _assignments!.length,
        separatorBuilder: (_, _) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final a = _assignments![index];
          return AssignmentCard(
            title: a.title,
            courseName: a.courseName,
            doneCount: a.doneCount,
            totalCount: a.totalCount,
            deadlineDays: a.deadlineDays,
            status: a.status,
            onTap: () => RouterUtils.push(context,'${AppRoutes.homeworkDetail}?id=${a.id}'),
          );
        },
      ),
    );
  }
}



