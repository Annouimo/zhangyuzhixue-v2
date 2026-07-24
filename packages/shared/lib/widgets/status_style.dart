import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 状态标签样式 — 跨页面共享
({String label, Color color, Color bg}) statusStyle(String status) {
  switch (status) {
    case 'completed':
      return (
        label: '已完成',
        color: colors.success,
        bg: colors.statusCompletedBg,
      );
    case 'in_progress':
      return (
        label: '进行中',
        color: colors.warning,
        bg: colors.statusInProgressBg,
      );
    default:
      return (
        label: '未做',
        color: colors.textSecondary,
        bg: colors.statusPendingBg,
      );
  }
}
