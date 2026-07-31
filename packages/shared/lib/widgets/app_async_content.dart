import 'package:flutter/material.dart';

import 'app_state_panel.dart';

/// 统一切换页面的加载、错误、空内容与正常内容状态。
///
/// 数据加载和刷新仍由页面或 controller 负责，避免把业务生命周期塞进展示组件。
class AppAsyncContent extends StatelessWidget {
  const AppAsyncContent({
    super.key,
    required this.loading,
    required this.empty,
    required this.child,
    this.error,
    this.loadingTitle = '正在加载',
    this.emptyTitle = '暂无内容',
    this.emptyMessage,
    this.emptyIcon,
    this.onRetry,
  });

  final bool loading;
  final bool empty;
  final String? error;
  final String loadingTitle;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return AppStatePanel(title: loadingTitle, tone: AppStateTone.loading);
    }
    if (error != null) {
      return AppStatePanel(
        title: '加载失败',
        message: error,
        tone: AppStateTone.error,
        actionLabel: onRetry == null ? null : '重试',
        onAction: onRetry,
      );
    }
    if (empty) {
      return AppStatePanel(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
        tone: AppStateTone.empty,
      );
    }
    return child;
  }
}
