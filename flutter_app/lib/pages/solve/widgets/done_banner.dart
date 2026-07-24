import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 完成横幅 — 选填共用
/// 🎉 已完成 + [下一题 →] [⭐ 评分]
class DoneBanner extends StatelessWidget {
  final bool isRated;
  final VoidCallback? onNext;
  final VoidCallback? onRate;

  DoneBanner({super.key, this.isRated = false, this.onNext, this.onRate});

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.celebration, size: 20, color: colors.primary),
        SizedBox(width: 8),
        Text(isRated ? '已完成 — 已评分' : '已完成',
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: colors.primary,
          ),
        ),
        Spacer(),
        if (onNext != null)
          TextButton.icon(
            onPressed: onNext,
            icon: Text('下一题'),
            label: Icon(Icons.arrow_forward, size: 16),
          ),
        if (onRate != null)
          TextButton(
            onPressed: onRate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: colors.warning),
                SizedBox(width: 4),
                Text('评分'),
              ],
            ),
          ),
      ]),
    );
  }
}
