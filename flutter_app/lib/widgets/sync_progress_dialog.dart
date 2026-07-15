import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';

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

  const _SyncProgressDialog({
    required this.task,
    required this.completer,
    this.dataVerifier,
    this.dialogTitle = '同步数据',
    this.dialogMessage = '正在从服务器恢复学习记录…',
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
    return PopScope(
      canPop: _status != 'progress',
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.file_download, size: 40, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          widget.dialogTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.dialogMessage,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_progress * 100).round()}%',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 40, color: AppColors.success),
        const SizedBox(height: 12),
        const Text(
          '同步完成',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '学习记录已恢复',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  Widget _buildNoData() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 40, color: AppColors.warning),
        const SizedBox(height: 12),
        const Text(
          '同步完成',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '服务器暂无学习记录可恢复，\n请先练习后再试',
          style: TextStyle(fontSize: 13, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  Widget _buildFail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 40, color: AppColors.error),
        const SizedBox(height: 12),
        const Text(
          '同步失败',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage.isNotEmpty ? _errorMessage : '网络异常，请稍后重试',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
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
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('重试'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('关闭'),
            ),
          ],
        ),
      ],
    );
  }
}
