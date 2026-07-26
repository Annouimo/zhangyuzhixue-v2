import 'package:flutter/material.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/theme/app_icons.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/loading_indicator.dart';

import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/question_repository.dart';
import '../domain/recommend_repository.dart';
import 'widgets/recommend_card.dart';

/// 推荐页（双模式：智能推荐 / 偏好推荐）
class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, this.recommendRepository});

  final RecommendRepository? recommendRepository;

  @override
  State<RecommendPage> createState() => RecommendPageState();
}

class RecommendPageState extends State<RecommendPage> {
  late RecommendRepository _repo;
  bool _loading = true;
  String? _error;
  List<RecommendedQuestion>? _questions;
  bool _preferSmart = true;
  List<RecommendPreset> _presets = [];
  int _selectedPresetIndex = -1;

  void _initRepo() {
    _repo =
        widget.recommendRepository ??
        RecommendRepository(
          QuestionDao(DatabaseProvider()),
          ProgressDao(DatabaseProvider()),
        );
  }

  /// 供 MainShell 切换 Tab 时调用：静默刷新，不打断用户阅读。
  void refresh() {
    _initRepo();
    _loadSilent();
  }

  Future<void> _loadSilent() async {
    _initRepo();
    try {
      final presets = await _repo.getPresets();
      final smart = await _repo.getSmartList();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        if (!_preferSmart) return;
        _questions = smart;
        _preferSmart = smart.isNotEmpty || presets.isEmpty;
      });
    } catch (_) {
      // 静默刷新失败时保留已有内容。
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _initRepo();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final presets = await _repo.getPresets();
      final smart = await _repo.getSmartList();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _questions = smart;
        _preferSmart = smart.isNotEmpty || presets.isEmpty;
        _loading = false;
      });
      AuditLogger.instance.page('RecommendPage', {
        'presetCount': _presets.length,
        'smartCount': _questions?.length,
        'preferSmart': _preferSmart,
      });
    } catch (error) {
      OperationLog.instance.error('RecommendPage._load', error);
      AuditLogger.instance.error('RecommendPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _switchToSmart() async {
    _initRepo();
    setState(() {
      _loading = true;
      _error = null;
      _preferSmart = true;
    });
    try {
      final questions = await _repo.getSmartList();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (error) {
      OperationLog.instance.error('RecommendPage._switchToSmart', error);
      AuditLogger.instance.error('RecommendPage._switchToSmart', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  void _switchToPresetMode() {
    if (_presets.isEmpty) return;
    final index = _selectedPresetIndex >= 0 ? _selectedPresetIndex : 0;
    _switchToPreset(index);
  }

  Future<void> _switchToPreset(int index) async {
    if (index < 0 || index >= _presets.length) return;
    _initRepo();
    setState(() {
      _loading = true;
      _error = null;
      _preferSmart = false;
      _selectedPresetIndex = index;
    });
    try {
      final presetQuestions = await _repo.getPresetQuestions(
        _presets[index].id,
      );
      if (!mounted) return;
      setState(() {
        _questions = presetQuestions
            .map(
              (question) => RecommendedQuestion(
                id: question.id,
                title: question.title,
                questionType: question.questionType,
                difficulty: question.difficulty,
                recommendReason: '符合“${_presets[index].name}”学习偏好',
                status: question.status,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (error) {
      OperationLog.instance.error('RecommendPage._switchToPreset', error);
      AuditLogger.instance.error('RecommendPage._switchToPreset', error);
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
      appBar: AppBar(
        title: const Text('题目推荐'),
        actions: [
          IconButton(
            tooltip: '刷新推荐',
            onPressed: _load,
            icon: const Icon(AppIcons.refresh),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingIndicator(message: '正在生成适合你的练习…');
    }
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }

    return AppContentContainer(
      maxWidth: AppContentWidth.standard,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroCard(),
            const SizedBox(height: AppSpacing.md),
            _RecommendationModeSelector(
              smartSelected: _preferSmart,
              presetEnabled: _presets.isNotEmpty,
              onSmartTap: _preferSmart ? null : _switchToSmart,
              onPresetTap: !_preferSmart ? null : _switchToPresetMode,
            ),
            if (!_preferSmart) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPresetSelector(),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(
              title: _preferSmart ? '智能推荐题目' : '偏好推荐题目',
              subtitle: _preferSmart ? '结合做题记录与薄弱知识点动态生成' : '根据选定的学习范围筛选题目',
              action: AppStatusBadge(
                label: '${_questions?.length ?? 0} 题',
                tone: AppStatusTone.neutral,
                compact: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildQuestionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.recommendationContainer,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: colors.recommendation),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.recommendation,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: colors.onRecommendation,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '把下一步练习交给推荐系统',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.onRecommendationContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _preferSmart
                      ? '优先补足薄弱知识点，并兼顾题型与难度。'
                      : '使用你保存的学习偏好，快速生成一组针对性练习。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onRecommendationContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedPresetIndex >= 0 ? _selectedPresetIndex : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: '学习偏好',
          prefixIcon: Icon(Icons.tune_rounded),
          helperText: '选择后会按偏好条件重新生成题目',
        ),
        hint: const Text('请选择一个学习偏好'),
        items: List.generate(
          _presets.length,
          (index) => DropdownMenuItem<int>(
            value: index,
            child: Text(_presets[index].name),
          ),
        ),
        onChanged: (value) {
          if (value != null) _switchToPreset(value);
        },
      ),
    );
  }

  Widget _buildQuestionList() {
    final questions = _questions ?? const <RecommendedQuestion>[];
    if (questions.isEmpty) {
      final needsPresetSelection = !_preferSmart && _selectedPresetIndex < 0;
      return EmptyPlaceholder(
        icon: _preferSmart
            ? Icons.auto_awesome_outlined
            : Icons.playlist_add_outlined,
        message: _preferSmart
            ? '暂时没有智能推荐，先完成几道练习积累学习记录'
            : needsPresetSelection
            ? '请先选择一个学习偏好开始推荐'
            : '当前偏好下暂无题目，可以尝试选择其他学习偏好',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final question = questions[index];
          return RecommendCard(
            title: question.title,
            questionType: question.questionType,
            difficulty: question.difficulty,
            reason: question.recommendReason,
            status: question.status,
            onTap: () => SolveRouteHelper.navigateTo(
              context,
              question.id,
              question.questionType,
            ),
          );
        },
      ),
    );
  }
}

class _RecommendationModeSelector extends StatelessWidget {
  const _RecommendationModeSelector({
    required this.smartSelected,
    required this.presetEnabled,
    required this.onSmartTap,
    required this.onPresetTap,
  });

  final bool smartSelected;
  final bool presetEnabled;
  final VoidCallback? onSmartTap;
  final VoidCallback? onPresetTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: '智能推荐',
              subtitle: '根据学习记录',
              icon: Icons.auto_awesome_outlined,
              selected: smartSelected,
              onTap: onSmartTap,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: _ModeOption(
              label: '偏好推荐',
              subtitle: presetEnabled ? '根据保存偏好' : '暂无可用偏好',
              icon: Icons.tune_rounded,
              selected: !smartSelected,
              enabled: presetEnabled,
              onTap: onPresetTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final foreground = !enabled
        ? colors.disabledForeground
        : selected
        ? colors.onPrimaryContainer
        : colors.textSecondary;

    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(color: foreground),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
