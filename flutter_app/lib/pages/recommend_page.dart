import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/recommend_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_placeholder.dart';
import '../../widgets/shared/error_placeholder.dart';
import 'widgets/recommend_card.dart';

/// 推荐页（双模式：智能推荐 / 偏好推荐）
class RecommendPage extends StatefulWidget {
  final RecommendRepository? recommendRepository;
  const RecommendPage({super.key, this.recommendRepository});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late final RecommendRepository _repo;
  bool _loading = true;
  String? _error;
  List<RecommendedQuestion>? _questions;
  bool _preferSmart = true; // true=智能推荐, false=偏好推荐
  int _presetCount = 0;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.recommendRepository ?? RecommendRepository(
      QuestionDao(db.assetsDb), ProgressDao(db.appDb),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final presets = await _repo.getPresets();
      final smart = await _repo.getSmartList();
      if (!mounted) return;
      setState(() {
        _presetCount = presets.length;
        _questions = smart;
        // 默认策略：做题<5且有偏好→偏好推荐，否则智能推荐
        // smart.isEmpty 等价于「做题<5」——RecommendationEngine 在
        // coldStartThreshold(5) 以下返回空列表，见 recommend_repository.dart
        if (smart.isEmpty && presets.isNotEmpty) { _preferSmart = false; }
        else { _preferSmart = true; }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _switchToSmart() async {
    setState(() { _loading = true; _preferSmart = true; });
    try {
      final qs = await _repo.getSmartList();
      if (!mounted) return;
      setState(() { _questions = qs; _loading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  Future<void> _switchToPreset(int index) async {
    setState(() { _loading = true; _preferSmart = false; });
    try {
      // 取第一个预设题目列表（简化：UI 支持切换但数据层 getPresetQuestions 暂时返回空）
      final qs = await _repo.getPresetQuestions(index + 1);
      if (!mounted) return;
      setState(() { _questions = qs.map((p) => RecommendedQuestion(
        id: p.id, title: p.title, questionType: p.questionType,
        difficulty: p.difficulty, recommendReason: '偏好推荐', status: p.status,
      )).toList(); _loading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_preferSmart ? '🔮 智能推荐' : '📋 偏好推荐'),
      actions: [
        if (_presetCount > 0)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '切换推荐模式',
            onSelected: (v) {
              if (v == 'smart') { _switchToSmart(); }
              else { _switchToPreset(int.tryParse(v) ?? 0); }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'smart', child: Text('🔮 智能推荐')),
              ...List.generate(_presetCount, (i) => PopupMenuItem(
                value: '${i + 1}', child: Text('📋 偏好推荐 ${i + 1}'),
              )),
            ],
          ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '生成推荐…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    if (_questions == null || _questions!.isEmpty) {
      return const EmptyPlaceholder(icon: '🔮', message: '暂无推荐，先去组卷或做几道题吧');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _questions!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final q = _questions![i];
          return RecommendCard(
            title: q.title,
            questionType: q.questionType,
            difficulty: q.difficulty,
            reason: q.recommendReason,
            onTap: () => context.push('/solve/choice?id=${q.id}'),
          );
        },
      ),
    );
  }
}
