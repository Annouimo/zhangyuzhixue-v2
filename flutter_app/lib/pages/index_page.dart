import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';

/// 首页
class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

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
                    // 切换到作业 tab
                  },
                ),
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickEntryGrid(context),
              const SizedBox(height: 24),
              const Text('📖 继续学习', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildRecentStudyPlaceholder(),
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
        const Text('🏠 快捷入口', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _QuickEntryCard(icon: Icons.auto_awesome, label: '智能推荐', onTap: () => context.push('/recommend')),
            _QuickEntryCard(icon: Icons.edit_note, label: '自主选题', onTap: () => context.push('/exam/pick')),
            _QuickEntryCard(icon: Icons.history, label: '我的组卷', onTap: () => context.push('/exam/history')),
            _QuickEntryCard(icon: Icons.explore, label: '发现组卷', onTap: () => context.push('/exam/explore')),
            _QuickEntryCard(icon: Icons.star_border, label: '收藏', onTap: () => context.push('/exam/favorites')),
            _QuickEntryCard(icon: Icons.bar_chart, label: '学习统计', onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('「学习统计」将在后续版本中实现'), behavior: SnackBarBehavior.floating))),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentStudyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Row(
        children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.school_outlined, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 14,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 180, height: 12,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
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
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
