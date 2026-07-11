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
  bool _preferSmart = true;
  List<RecommendPreset> _presets = [];
  int _selectedPresetIndex = 0;

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
        _presets = presets;
        _questions = smart;
        // 默认策略：做题<5且有偏好→偏好推荐，否则智能推荐
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
    if (index < 0 || index >= _presets.length) return;
    setState(() { _loading = true; _preferSmart = false; _selectedPresetIndex = index; });
    try {
      final presetId = _presets[index].id;
      final qs = await _repo.getPresetQuestions(presetId);
      if (!mounted) return;
      setState(() { _questions = qs.map((p) => RecommendedQuestion(
        id: p.id, title: p.title, questionType: p.questionType,
        difficulty: p.difficulty, recommendReason: '偏好推荐', status: p.status,
      )).toList(); _loading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('题目推荐')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '生成推荐…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    return Column(
      children: [
        _buildModePills(),
        if (!_preferSmart && _presets.length > 1)
          _buildPresetSelector(),
        Expanded(
          child: _questions == null || _questions!.isEmpty
              ? const EmptyPlaceholder(icon: '🔮', message: '暂无推荐，先去组卷或做几道题吧')
              : RefreshIndicator(
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
                ),
        ),
      ],
    );
  }

  Widget _buildModePills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.baseSpacing, vertical: 8),
      child: Row(
        children: [
          _PillButton(
            selected: _preferSmart,
            label: '🔮 智能推荐',
            onPressed: _switchToSmart,
          ),
          const SizedBox(width: 8),
          _PillButton(
            selected: !_preferSmart,
            label: '📋 偏好推荐',
            onPressed: _presets.isNotEmpty ? () => _switchToPreset(_selectedPresetIndex) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.baseSpacing),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择学习偏好',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              DropdownButton<int>(
                value: _selectedPresetIndex,
                isExpanded: true,
                underline: const SizedBox(),
                items: List.generate(_presets.length, (i) => DropdownMenuItem(
                  value: i,
                  child: Text(_presets[i].name, style: const TextStyle(fontSize: 14)),
                )),
                onChanged: (value) {
                  if (value != null) _switchToPreset(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback? onPressed;

  const _PillButton({
    required this.selected,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
