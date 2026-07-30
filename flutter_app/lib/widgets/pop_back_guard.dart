import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'exit_rating_popup.dart';

/// PopScope 守卫：防止 GoRouter 17.x 中 PopScope 二次进入导致的级联弹出
///
/// 用法：
/// ```dart
/// final PopBackGuard _popGuard = PopBackGuard();
/// // ...
/// onPopInvokedWithResult: (didPop, _) =>
///   _popGuard.handlePop(context, 'page_name'),
/// ```
/// consume() 在第一次调用时执行 showExitRatingIfNeeded 并返回 true；
/// 若 PopScope 二次触发（GoRouter 17.x bug），consume 直接返回 false，阻止级联。
class PopBackGuard {
  PopBackGuard({
    Future<bool> Function(BuildContext, String, DateTime)? showExitRating,
  }) : _showExitRating = showExitRating ?? showExitRatingIfNeeded;

  final Future<bool> Function(BuildContext, String, DateTime) _showExitRating;
  DateTime? _guard = DateTime.now();

  /// 消耗守卫并执行退出评分弹窗
  /// 返回 true 表示可以继续执行 context.pop()
  Future<bool> consume(BuildContext context, String pageName) async {
    if (_guard == null) return false;
    final time = _guard!;
    _guard = null;
    await _showExitRating(context, pageName, time);
    return context.mounted;
  }

  /// Runs the exit guard and pops only while the router still has a route.
  ///
  /// A redirect or `go()` can replace the route while the asynchronous exit
  /// prompt is open. In that case the original navigation already won and a
  /// second pop would throw `GoError: There is nothing to pop`.
  Future<void> handlePop(BuildContext context, String pageName) async {
    if (!await consume(context, pageName) || !context.mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }
}
