import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// 讲义翻页与逐段展开栏。
class LecturePagerWidget extends StatelessWidget {
  const LecturePagerWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.revealedCount,
    required this.totalBlocks,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int revealedCount;
  final int totalBlocks;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  bool get _canPrev => currentPage > 1 || revealedCount > 1;
  bool get _canNext => currentPage < totalPages || revealedCount < totalBlocks;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final revealing = revealedCount < totalBlocks;
    final nextLabel = revealing ? '继续展开' : '下一页';

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.divider)),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? AppShadows.low
              : null,
        ),
        child: SafeArea(
          top: false,
          child: AppContentContainer(
            maxWidth: AppContentWidth.reading,
            useSafeArea: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton.outlined(
                  tooltip: revealedCount > 1 ? '收回上一段' : '上一页',
                  onPressed: _canPrev ? onPrev : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '第 $currentPage / $totalPages 页',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '当前页已展开 $revealedCount / $totalBlocks 段',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _canNext ? onNext : null,
                  icon: Icon(
                    revealing
                        ? Icons.unfold_more_rounded
                        : Icons.chevron_right_rounded,
                    size: 19,
                  ),
                  label: Text(nextLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
