import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 完成横幅 — 选填共用
/// 🎉 已完成 + [下一题 →] [⭐ 评分]
class DoneBanner extends StatelessWidget {
  final bool isRated;
  final VoidCallback? onNext;
  final VoidCallback? onRate;

  const DoneBanner({super.key, this.isRated = false, this.onNext, this.onRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.celebration, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(isRated ? '已完成 — 已评分' : '已完成',
          style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary,
          ),
        ),
        const Spacer(),
        if (onNext != null)
          TextButton.icon(
            onPressed: onNext,
            icon: const Text('下一题'),
            label: const Icon(Icons.arrow_forward, size: 16),
          ),
        if (onRate != null)
          TextButton(
            onPressed: onRate,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: AppColors.warning),
                SizedBox(width: 4),
                Text('评分'),
              ],
            ),
          ),
      ]),
    );
  }
}
