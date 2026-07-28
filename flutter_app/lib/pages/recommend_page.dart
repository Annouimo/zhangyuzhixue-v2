import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/question_repository.dart';
import '../domain/recommend_repository.dart';

/// 本地连续推荐页。页面只展示当前题目，完整作答复用既有解题流程。
class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, this.recommendRepository});

  final RecommendRepository? recommendRepository;

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
    await _load(silent: _current != null);
  }

  Future<void> _load({bool silent = false}) async {
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
      if (!mounted) return;
      setState(() {
        _queue = filtered.isEmpty ? questions : filtered;
        _currentIndex = 0;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '暂时无法生成推荐，请稍后重试';
        _loading = false;
      });
    }
  }

  void _next() {
    final current = _current;
    if (current != null) _seenInSession.add(current.id);
    if (_currentIndex + 1 < _queue.length) {
      setState(() => _currentIndex++);
    } else {
      _load();
    }
  }

  Future<void> _start() async {
    final current = _current;
    if (current == null) return;
    _seenInSession.add(current.id);
    final sequence = _queue
        .skip(_currentIndex)
        .map((question) => question.id)
        .toList(growable: false);
    await SolveRouteHelper.navigateTo(
      context,
      current.id,
      current.questionType,
      sequence: sequence,
      forceNewAttempt: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('推荐'),
        actions: [
          IconButton(
            tooltip: '重新生成推荐',
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(AppIcons.refresh),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _buildBody(current),
      bottomNavigationBar: current == null ? null : _buildActions(current),
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

    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Row(
            children: [
              AppStatusBadge(
                label: current.recommendReason,
                tone: AppStatusTone.recommendation,
                icon: Icons.auto_awesome_rounded,
                compact: true,
              ),
              const Spacer(),
              Text(
                '${_currentIndex + 1}/${_queue.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label: QuestionTypeLabels.of(current.questionType),
                      tone: AppStatusTone.info,
                      compact: true,
                    ),
                    if (current.difficulty > 0)
                      AppStatusBadge(
                        label: '难度 ${current.difficulty.toStringAsFixed(1)}',
                        tone: AppStatusTone.neutral,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                MdLatexBody(current.title, fontSize: 17),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildActions(RecommendedQuestion current) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: '下一题',
                      icon: Icons.skip_next_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: _next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: '开始作答',
                      icon: Icons.edit_rounded,
                      onPressed: _start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
