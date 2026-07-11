import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/database/database_provider.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../widgets/shared/loading_indicator.dart';

/// 首页
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});
  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _pendingCount = 0;
  bool _loading = true;
  bool _hasHistory = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('pending_homework_count') ?? 0;
      if (!mounted) return;
      setState(() => _pendingCount = count);
    } catch (_) {}
    try {
      final dao = ProgressDao(DatabaseProvider().appDb);
      final hasHistory = await dao.hasAnySubmission();
      if (!mounted) return;
      setState(() { _hasHistory = hasHistory; _loading = false; });
    } catch (e) {
      debugPrint('IndexPage _load error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('章鱼智学'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment_outlined),
                  onPressed: () {
                    // 切换到作业 tab（预留）
                  },
                ),
                if (_pendingCount > 0)
                  Positioned(
                    right: 6, top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text('$_pendingCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.baseSpacing),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickEntryGrid(context),
                    const SizedBox(height: 24),
                    const Text('📖 继续学习',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _hasHistory
                        ? _buildRecentStudyCard()
                        : _buildEmptyPlaceholder(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickEntryGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏠 快捷入口',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _QuickEntryCard(icon: Icons.auto_awesome, label: '智能推荐', onTap: () => context.push('/recommend')),
            _QuickEntryCard(icon: Icons.edit_note, label: '自主选题', onTap: () => context.push('/exam/pick')),
            _QuickEntryCard(icon: Icons.history, label: '我的组卷', onTap: () => context.push('/exam/history')),
            _QuickEntryCard(icon: Icons.explore, label: '发现组卷', onTap: () => context.push('/exam/explore')),
            _QuickEntryCard(icon: Icons.star_border, label: '收藏', onTap: () => context.push('/exam/favorites')),
            _QuickEntryCard(icon: Icons.bar_chart, label: '学习统计', onTap: () => context.push('/statistics')),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentStudyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('继续上一次学习',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push('/exam/pick'),
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: const Center(
        child: Text('暂无学习记录，去选题试试吧',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ),
    );
  }
}

class _QuickEntryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickEntryCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
