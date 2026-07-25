import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';

/// 冷却倒计时组件 — 纯展示，由外层通过 GlobalKey 控制。
class CoolingTimer extends StatefulWidget {
  const CoolingTimer({
    super.key,
    required this.seconds,
    this.label = '可提交',
    this.child,
    this.onCooldownEnd,
  });

  final int seconds;
  final String label;
  final Widget? child;
  final VoidCallback? onCooldownEnd;

  @override
  CoolingTimerState createState() => CoolingTimerState();
}

class CoolingTimerState extends State<CoolingTimer> {
  int _remaining = 0;
  bool _active = false;
  Timer? _timer;

  bool get isCoolingDown => _active && _remaining > 0;

  void start() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.seconds;
      _active = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() => _remaining = 0);
        widget.onCooldownEnd?.call();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void reset() {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _active = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!_active) return widget.child ?? const SizedBox.shrink();
    if (_remaining <= 0) return widget.child ?? const SizedBox.shrink();

    final total = widget.seconds <= 0 ? 1 : widget.seconds;
    final progress = 1 - (_remaining / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: 0.48,
          child: AbsorbPointer(absorbing: true, child: widget.child),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress.clamp(0.0, 1.0).toDouble(),
            backgroundColor: colors.surfaceSubtle,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '阅读后还需 $_remaining 秒${widget.label}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
