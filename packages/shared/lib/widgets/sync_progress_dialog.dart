import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 同步进度弹窗
///
/// 三种场景（通过 title/message 区分）：
/// - 登录同步：title="恢复数据" message="正在从服务器恢复你的学习记录…"
/// - 手动同步：title="同步数据" message="正在上传本地数据并下载最新记录…"
/// - 版本更新：title="更新数据" message="正在下载新版本…"
///
/// 用法：
/// ```dart
/// final ok = await showSyncProgress(context, (onProgress) async {
///   await SyncManager().forcePull(onProgress: onProgress);
/// });
/// ```
///
/// [dataVerifier] 可选：成功后检查是否有可恢复的数据，返回 false 时显示"未发现"提示。
Future<bool> showSyncProgress(
  BuildContext context,
  Future<void> Function(void Function(double) onProgress) task, {
  Future<bool> Function()? dataVerifier,
  String title = '同步数据',
  String message = '正在同步…',
}) async {
  final completer = Completer<bool>();

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SyncProgressDialog(
      task: task,
      completer: completer,
      dataVerifier: dataVerifier,
      dialogTitle: title,
      dialogMessage: message,
    ),
  );

  return completer.future;
}

class _SyncProgressDialog extends StatefulWidget {
  final Future<void> Function(void Function(double) onProgress) task;
  final Completer<bool> completer;
  final Future<bool> Function()? dataVerifier;
  final String dialogTitle;
  final String dialogMessage;

  _SyncProgressDialog({
    required this.task,
    required this.completer,
    this.dataVerifier,
    this.dialogTitle = '同步数据',
    this.dialogMessage = '正在同步…',
  });

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  double _progress = 0;
  String _status = 'progress'; // progress | done | no_data | fail
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      await widget.task((p) {
        if (mounted) setState(() => _progress = p);
      });

      // 有 dataVerifier 则检查数据是否非空
      if (widget.dataVerifier != null) {
        final hasData = await widget.dataVerifier!();
        if (mounted) {
          setState(() => _status = hasData ? 'done' : 'no_data');
        }
        widget.completer.complete(hasData);
      } else {
        if (mounted) setState(() => _status = 'done');
        widget.completer.complete(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'fail';
          _errorMessage = e.toString();
        });
      }
      widget.completer.complete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return PopScope(
      canPop: _status != 'progress',
      child: AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(24, 28, 24, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: 280,
          child: _status == 'progress'
              ? _buildProgress()
              : _status == 'done'
                  ? _buildDone()
                  : _status == 'no_data'
                      ? _buildNoData()
                      : _buildFail(),
        ),
      ),
    );
  }

  Widget _buildProgress() {
      final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.file_download, size: 40, color: colors.primary),
        SizedBox(height: 12),
        Text(
          widget.dialogTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          widget.dialogMessage,
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${(_progress * 100).round()}%',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildDone() {
      final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 40, color: colors.success),
        SizedBox(height: 12),
        Text(
          '同步完成',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          '学习记录已恢复',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 40),
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('知道了'),
        ),
      ],
    );
  }

  Widget _buildNoData() {
      final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, size: 40, color: colors.warning),
        SizedBox(height: 12),
        Text(
          '同步完成',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          '服务器暂无学习记录可恢复，\n请先练习后再试',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 40),
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('知道了'),
        ),
      ],
    );
  }

  Widget _buildFail() {
      final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error, size: 40, color: colors.error),
        SizedBox(height: 12),
        Text(
          '同步失败',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          _errorMessage.isNotEmpty ? _errorMessage : '网络异常，请稍后重试',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _status = 'progress';
                  _progress = 0;
                  _errorMessage = '';
                });
                _runTask();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('重试'),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('关闭'),
            ),
          ],
        ),
      ],
    );
  }
}
