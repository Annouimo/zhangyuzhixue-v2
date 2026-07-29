import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/recommend_repository.dart';
import 'solve/solve_choice_page.dart';
import 'solve/solve_fill_page.dart';
import 'solve/solve_map_page.dart';
import 'solve/widgets/question_contribution_actions.dart';

typedef RecommendSolveBuilder =
    Widget Function(RecommendedQuestion question, VoidCallback onNext);

/// 本地连续推荐页。页面只展示当前题目，完整作答复用既有解题流程。
class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, this.recommendRepository, this.solveBuilder});

  final RecommendRepository? recommendRepository;
  final RecommendSolveBuilder? solveBuilder;

  @override
  State<RecommendPage> createState() => RecommendPageState();
}

class RecommendPageState extends State<RecommendPage> {
  late RecommendRepository _repository;
  List<RecommendedQuestion> _queue = const [];
  final Set<int> _seenInSession = {};
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;
  int _requestGeneration = 0;

  static const int _minimumBufferedQuestions = 2;

  RecommendedQuestion? get _current =>
      _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  @visibleForTesting
  int get debugQueueLength => _queue.length;

  @visibleForTesting
  String? get debugLoadError => _error;

  @visibleForTesting
  bool get debugLoading => _loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _initRepository() {
    _repository =
        widget.recommendRepository ??
        RecommendRepository(
          QuestionDao(DatabaseProvider()),
          ProgressDao(DatabaseProvider()),
        );
  }

  Future<void> refresh() async {
    if (_current == null) {
      await _load();
    } else {
      await _refreshTail();
    }
  }

  Future<void> _load({bool silent = false}) async {
    final generation = ++_requestGeneration;
    _initRepository();
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final questions = await _repository.getSmartList();
      final filtered = questions
          .where((question) => !_seenInSession.contains(question.id))
          .toList(growable: false);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _queue = filtered.isEmpty ? questions : filtered;
        _currentIndex = 0;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = '暂时无法生成推荐，请稍后重试';
        _loading = false;
      });
    }
  }

  void _skipCurrent() {
    _advance(recompute: false);
  }

  void _completeAndAdvance() {
    _advance(recompute: true);
  }

  void _advance({required bool recompute}) {
    final current = _current;
    if (current != null) _seenInSession.add(current.id);
    if (_currentIndex + 1 < _queue.length) {
      setState(() => _currentIndex++);
      final remaining = _queue.length - _currentIndex - 1;
      if (recompute || remaining < _minimumBufferedQuestions) {
        _refreshTail();
      }
    } else {
      _load();
    }
  }

  Future<void> _refreshTail() async {
    final current = _current;
    if (current == null) return _load();
    final currentId = current.id;
    final generation = ++_requestGeneration;
    _initRepository();
    try {
      final questions = await _repository.getSmartList();
      if (!mounted || generation != _requestGeneration) return;
      if (_current?.id != currentId) return;
      final tail = questions
          .where(
            (question) =>
                question.id != currentId &&
                !_seenInSession.contains(question.id),
          )
          .toList(growable: false);
      final existingTail = _queue
          .skip(_currentIndex + 1)
          .where(
            (question) =>
                question.id != currentId &&
                !_seenInSession.contains(question.id),
          )
          .toList(growable: false);
      setState(() {
        _queue = [current, ...(tail.isEmpty ? existingTail : tail)];
        _currentIndex = 0;
      });
    } catch (_) {
      // A background refresh must never replace a usable current question.
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('推荐'),
        actions: [
          if (current != null)
            ...questionContributionActions(context, current.id),
          if (current != null)
            IconButton(
              tooltip: '换一题',
              onPressed: _skipCurrent,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _buildBody(current),
    );
  }

  Widget _buildBody(RecommendedQuestion? current) {
    if (_loading) return const LoadingIndicator(message: '正在选择下一道题…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    if (current == null) {
      return EmptyPlaceholder(
        icon: Icons.auto_awesome_outlined,
        message: '当前没有可推荐的题目，请先检查题库数据',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      current.recommendReason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildSolve(current)),
      ],
    );
  }

  Widget _buildSolve(RecommendedQuestion current) {
    final builder = widget.solveBuilder;
    if (builder != null) return builder(current, _completeAndAdvance);
    return switch (current.questionType) {
      'choice' => SolveChoicePage(
        key: ValueKey('recommend-choice-${current.id}'),
        questionId: current.id,
        embedded: true,
        forceNewAttempt: true,
        onNext: _completeAndAdvance,
      ),
      'fill' => SolveFillPage(
        key: ValueKey('recommend-fill-${current.id}'),
        questionId: current.id,
        embedded: true,
        forceNewAttempt: true,
        onNext: _completeAndAdvance,
      ),
      _ => SolveMapPage(
        key: ValueKey('recommend-solution-${current.id}'),
        questionId: current.id,
        embedded: true,
        forceNewAttempt: true,
        onNext: _completeAndAdvance,
      ),
    };
  }
}
