import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/app_toast.dart';

/// 池子不足弹窗 — 匹配 HTML 原型 shortfall-popup
///
/// 智能组卷/自主选题时，某题型数量不足时弹窗提示，
/// 提供「调整筛选条件」和「直接组卷」两个操作选项。
Future<void> showShortfallDialog(
  BuildContext context, {
  required String type,
  required int needed,
  required int available,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ShortfallDialog(type: type, needed: needed, available: available),
  );
  if (result == true && context.mounted) {
    AppToast.show(context,
      icon: Icons.description,
      message: '池子不足，按可用题目直接组卷',
    );
  }
}

class _ShortfallDialog extends StatelessWidget {
  final String type;
  final int needed;
  final int available;

  _ShortfallDialog({
    required this.type,
    required this.needed,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: colors.warning),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warningContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('池子不足',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onWarningContainer),
                ),
              ),
              SizedBox(height: 8),
              Text('题库数量不足',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                '$type 类题目池子不足\n（需要 $needed 道，池中只有 $available 道）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.border),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('调整筛选条件', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('直接组卷', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
