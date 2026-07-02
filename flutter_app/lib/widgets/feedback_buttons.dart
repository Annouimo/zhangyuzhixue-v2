import 'package:flutter/material.dart';

/// 反馈按钮（全对 / 过程对计算错 / 不会）
class FeedbackButtons extends StatelessWidget {
  final ValueChanged<String> onFeedback;

  const FeedbackButtons({super.key, required this.onFeedback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: _btn('全对', Colors.green, () => onFeedback('全对'))),
          const SizedBox(width: 8),
          Expanded(child: _btn('过程对计算错', Colors.orange, () => onFeedback('过程对计算错'))),
          const SizedBox(width: 8),
          Expanded(child: _btn('不会', Colors.red, () => onFeedback('不会'))),
        ],
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color)),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
