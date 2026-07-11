import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 冷却倒计时组件 — 纯展示，由外层通过 GlobalKey 控制
class CoolingTimer extends StatefulWidget {
  final int seconds;
  final Widget? child;
  final VoidCallback? onCooldownEnd;

  const CoolingTimer({
    super.key,
    required this.seconds,
    this.child,
    this.onCooldownEnd,
  });

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
    if (!_active) return widget.child ?? const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_remaining > 0) ...[
          Opacity(
            opacity: 0.4,
            child: AbsorbPointer(absorbing: true, child: widget.child),
          ),
          const SizedBox(height: 6),
          Text(
            '⏳ 还剩 $_remaining 秒可提交',
            style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12,
            ),
          ),
        ] else
          widget.child ?? const SizedBox.shrink(),
      ],
    );
  }
}
