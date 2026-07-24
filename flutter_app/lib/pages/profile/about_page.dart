import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/prefs/app_prefs.dart';
import '../../data/daos/sync_queue_dao.dart';
import '../../data/database/database_provider.dart';
import 'package:shared/constants/app_version.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 关于页 — 数据版本（题库/课程/用户数据）+ 法律信息
class AboutPage extends StatefulWidget {
  AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _lastSyncTime = '从未同步';

  int _localQbank = 0;
  int _localCourses = 0;
  int _localUser = 0;
  int _serverQbank = 0;
  int _serverCourses = 0;
  int _serverUser = 0;
  bool _versionLoaded = false;
  bool _versionError = false;
  bool _updatingQbank = false;
  bool _updatingCourses = false;
  bool _updatingUser = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = AppPrefs();
    _localQbank = prefs.qbankVersion;
    _localCourses = prefs.coursesVersion;
    _localUser = prefs.userVersion;

    final ts = prefs.lastSyncTime;
    final pullDate = ts != null ? DateTime.tryParse(ts) : null;

    // 取同步队列最新上传日期
    DateTime? uploadDate;
    try {
      final dao = SyncQueueDao(DatabaseProvider());
      uploadDate = await dao.getLatestUploadDate();
    } catch (_) {}

    // 取 pull 日期和 upload 日期中最新者
    final dates = <DateTime>[
      if (pullDate != null) pullDate,
      if (uploadDate != null) uploadDate,
    ];

    if (mounted) {
      if (dates.isNotEmpty) {
        final latestDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
        setState(() {
          final y = latestDate.year.toString();
          final m = latestDate.month.toString().padLeft(2, '0');
          final d = latestDate.day.toString().padLeft(2, '0');
          _lastSyncTime = '上次同步：$y-$m-$d';
        });
      }
    }

    // 后台检查服务器版本
    try {
      final mgr = SyncManager().updateManager;
      if (mgr != null) {
        final results = await mgr.checkAll();
        if (!mounted) return;
        for (final r in results) {
          if (r.type == 'qbank') _serverQbank = r.serverVersion;
          if (r.type == 'courses') _serverCourses = r.serverVersion;
          if (r.type == 'user') _serverUser = r.serverVersion;
        }
        setState(() => _versionLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() { _versionLoaded = true; _versionError = true; });
    }

    if (mounted) setState(() {});
    AuditLogger.instance.page('AboutPage', {'version': appVersion});
  }

  Future<void> _onUpdate(String type) async {
    final label = type == 'qbank' ? '题库' : (type == 'courses' ? '课程' : '学习记录');
    if (type == 'qbank') setState(() => _updatingQbank = true);
    if (type == 'courses') setState(() => _updatingCourses = true);
    if (type == 'user') setState(() => _updatingUser = true);

    await showSyncProgress(
      context,
      (onProgress) async {
        await SyncManager().runUpdate(type, onProgress: onProgress);
      },
      title: '更新数据',
      message: '正在下载$label新版本…',
    );

    if (!mounted) return;
    final prefs = AppPrefs();
    setState(() {
      if (type == 'qbank') {
        _localQbank = prefs.qbankVersion;
        _updatingQbank = false;
      }
      if (type == 'courses') {
        _localCourses = prefs.coursesVersion;
        _updatingCourses = false;
      }
      if (type == 'user') {
        _localUser = prefs.userVersion;
        _updatingUser = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('关于')),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.baseSpacing),
      child: Column(children: [
        SizedBox(height: 32),
        // ── 品牌标识 ──
        CircleAvatar(
          radius: 32,
          backgroundColor: context.colors.primaryContainer,
          child: Icon(Icons.school, size: 32, color: context.colors.primary),
        ),
        SizedBox(height: 10),
        Text(
          '章鱼智学',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(
          '版本 $appVersion',
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        SizedBox(height: 28),

        // ── 数据版本卡片 ──
        _buildSectionCard([
          _buildVersionTile(
            icon: Icons.storage,
            label: '题库',
            local: _localQbank,
            server: _serverQbank,
            updating: _updatingQbank,
            onUpdate: () => _onUpdate('qbank'),
          ),
          Divider(height: 1, indent: 48),
          _buildVersionTile(
            icon: Icons.article,
            label: '课程',
            local: _localCourses,
            server: _serverCourses,
            updating: _updatingCourses,
            onUpdate: () => _onUpdate('courses'),
          ),
          Divider(height: 1, indent: 48),
          _buildUserTile(),
        ]),
        SizedBox(height: 12),

        // ── 法律信息 ──
        _buildSectionCard([
          ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('用户协议', style: TextStyle(fontSize: 15)),
            trailing: Icon(Icons.chevron_right),
            onTap: () => launchUrl(Uri.parse('https://zhangyuzhixue.zhtec123.com/terms.html')),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('隐私政策', style: TextStyle(fontSize: 15)),
            trailing: Icon(Icons.chevron_right),
            onTap: () => launchUrl(Uri.parse('https://zhangyuzhixue.zhtec123.com/privacy.html')),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('官方网站', style: TextStyle(fontSize: 15)),
            trailing: Icon(Icons.chevron_right),
            onTap: () => launchUrl(Uri.parse('https://zhangyuzhixue.top/')),
          ),
        ]),

        Text(
          '© ${DateTime.now().year} 章鱼智学 · 北京',
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
        Text(
          '湘ICP备2026008095号-1',
          style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
        ),
        SizedBox(height: 16),
        _buildExportLogButton(),
        SizedBox(height: 8),
      ]),
    ),
  );

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildVersionTile({
    required IconData icon,
    required String label,
    required int local,
    required int server,
    required bool updating,
    required VoidCallback onUpdate,
  }) {
    if (_versionError) {
      return ListTile(
        leading: Icon(icon, color: context.colors.primary),
        title: Text(label, style: TextStyle(fontSize: 15)),
        subtitle: Text('⚠ 检查失败',
          style: TextStyle(fontSize: 12, color: context.colors.error),
        ),
        trailing: null,
      );
    }
    final hasUpdate = server > local;
    final statusText = !_versionLoaded
        ? 'v$local'
        : hasUpdate
            ? 'v$local → v$server 可用'
            : 'v$local (最新)';
    final statusColor = !_versionLoaded
        ? context.colors.textSecondary
        : hasUpdate
            ? context.colors.warning
            : context.colors.success;

    return ListTile(
      leading: Icon(icon, color: context.colors.primary),
      title: Text(label, style: TextStyle(fontSize: 15)),
      subtitle: Text(
        statusText,
        style: TextStyle(fontSize: 12, color: statusColor),
      ),
      trailing: hasUpdate
          ? ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 80),
              child: OutlinedButton(
                onPressed: updating ? null : onUpdate,
                child: updating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('更新'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.warning,
                  side: BorderSide(color: context.colors.warning),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  textStyle: TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildUserTile() {
    final hasUpdate = _serverUser > _localUser;
    return ListTile(
      leading: Icon(Icons.devices, color: context.colors.primary),
      title: Text('多设备同步数据', style: TextStyle(fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lastSyncTime,
            style: TextStyle(fontSize: 12),
          ),
          if (_versionLoaded && hasUpdate) ...[
            SizedBox(height: 4),
            Text(
              '检测到其他设备有新记录，建议同步',
              style: TextStyle(fontSize: 11, color: context.colors.warning),
            ),
          ],
        ],
      ),
      trailing: !_versionLoaded
          ? null
          : hasUpdate
              ? OutlinedButton(
                  onPressed: _updatingUser ? null : () => _onUpdate('user'),
                  child: _updatingUser
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('同步'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.warning,
                    side: BorderSide(color: context.colors.warning),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Icon(Icons.check_circle, size: 20, color: context.colors.success),
    );
  }

  /// ── 导出日志按钮 ──
  Widget _buildExportLogButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _exportLog,
        icon: Icon(Icons.bug_report_outlined, size: 16),
        label: Text('导出运行日志'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.textSecondary,
          side: BorderSide(color: context.colors.border),
          padding: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _exportLog() async {
    switch (await OperationLog.instance.exportToShare()) {
      case ExportResult.success:
        AppToast.show(context, icon: Icons.check_circle, message: '已打开分享面板');
      case ExportResult.fileNotFound:
        AppToast.show(context, icon: Icons.info, message: '暂无日志数据');
      case ExportResult.notReady:
      case ExportResult.savedToFolder:
        AppToast.show(context, icon: Icons.folder_open, message: '日志已导出到 Downloads 文件夹');
    }
  }
}
