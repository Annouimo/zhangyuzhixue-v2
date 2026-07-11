import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 翻页/展开栏组件
///
/// 智能决定 ◀/▶ 行为：
/// - ◀：有已展开块则收回，无则翻上一页
/// - ▶：有未展开块则展开，无则翻下一页
class LecturePagerWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int revealedCount;
  final int totalBlocks;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const LecturePagerWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.revealedCount,
    required this.totalBlocks,
    required this.onPrev,
    required this.onNext,
  });

  bool get _canPrev => currentPage > 1 || revealedCount > 0;
  bool get _canNext => currentPage < totalPages || revealedCount < totalBlocks;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildNavButton(
                icon: Icons.chevron_left,
                enabled: _canPrev,
                onTap: _canPrev ? onPrev : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '第 $currentPage / $totalPages 页 · 展开 $revealedCount / $totalBlocks',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildNavButton(
                icon: Icons.chevron_right,
                enabled: _canNext,
                onTap: _canNext ? onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: enabled ? AppColors.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.grey[400],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
