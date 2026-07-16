import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 状态标签样式 — 跨页面共享
({String label, Color color, Color bg}) statusStyle(String status) {
  switch (status) {
    case 'completed':
      return (
        label: '已完成',
        color: AppColors.success,
        bg: AppColors.statusCompletedBg,
      );
    case 'in_progress':
      return (
        label: '进行中',
        color: AppColors.warning,
        bg: AppColors.statusInProgressBg,
      );
    default:
      return (
        label: '未做',
        color: AppColors.textSecondary,
        bg: AppColors.statusPendingBg,
      );
  }
}
