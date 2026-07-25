import 'package:flutter/material.dart';
import 'exit_rating_popup.dart';

/// PopScope 守卫：防止 GoRouter 17.x 中 PopScope 二次进入导致的级联弹出
///
/// 用法：
/// ```dart
/// final PopBackGuard _popGuard = PopBackGuard();
/// // ...
/// onPopInvokedWithResult: (didPop, _) async {
///   if (await _popGuard.consume(context, 'page_name')) context.pop();
/// },
/// ```
/// consume() 在第一次调用时执行 showExitRatingIfNeeded 并返回 true；
/// 若 PopScope 二次触发（GoRouter 17.x bug），consume 直接返回 false，阻止级联。
class PopBackGuard {
  DateTime? _guard = DateTime.now();

  /// 消耗守卫并执行退出评分弹窗
  /// 返回 true 表示可以继续执行 context.pop()
  Future<bool> consume(BuildContext context, String pageName) async {
    if (_guard == null) return false;
    final time = _guard!;
    _guard = null;
    await showExitRatingIfNeeded(context, pageName, time);
    return context.mounted;
  }
}
