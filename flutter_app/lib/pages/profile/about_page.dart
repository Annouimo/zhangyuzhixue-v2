import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';
import '../../widgets/user_sync_progress.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/sync/update_manager.dart';
import '../../data/prefs/app_prefs.dart';
import '../../data/daos/sync_queue_dao.dart';
import '../../data/database/database_provider.dart';
import 'package:shared/constants/app_version.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 关于页 — 数据版本（题库/内容/用户数据）+ 法律信息
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

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
  bool _qbankVersionError = false;
  bool _coursesVersionError = false;
  bool _userVersionError = false;
  bool _updatingQbank = false;
  bool _updatingCourses = false;
  bool _updatingUser = false;
  bool _qbankDownloadReady = false;
  bool _coursesDownloadReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = AppPrefs();
    _localUser = prefs.userVersion;
    try {
      _localQbank = await DatabaseProvider().dataVersion('qbank');
      _localCourses = await DatabaseProvider().dataVersion('courses');
    } catch (e) {
      // 数据库是权威来源；仅在数据库尚未就绪的测试/异常环境回退缓存。
      _localQbank = prefs.qbankVersion;
      _localCourses = prefs.coursesVersion;
      AuditLogger.instance.error('AboutPage._loadLocalVersions', e);
    }

    final ts = prefs.lastSyncTime;
    if (ts != null) OperationLog.instance.action('about_lastSync', ts);
    final pullDate = ts != null ? DateTime.tryParse(ts) : null;

    // 取同步队列最新上传日期
    DateTime? uploadDate;
    try {
      final dao = SyncQueueDao(DatabaseProvider());
      uploadDate = await dao.getLatestUploadDate();
      if (uploadDate != null) {
        OperationLog.instance.action(
          'about_uploadDate',
          uploadDate.toIso8601String(),
        );
      } else {
        OperationLog.instance.action('about_uploadDate', 'null');
      }
    } catch (e) {
      OperationLog.instance.action('about_uploadDate', 'error: $e');
    }

    // 取 pull 日期和 upload 日期中最新者
    final dates = <DateTime>[?pullDate, ?uploadDate];

    if (mounted) {
      if (dates.isNotEmpty) {
        final latestDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
        OperationLog.instance.action(
          'about_sync_result',
          latestDate.toIso8601String(),
        );
        setState(() {
          final y = latestDate.year.toString();
          final m = latestDate.month.toString().padLeft(2, '0');
          final d = latestDate.day.toString().padLeft(2, '0');
          final h = latestDate.hour.toString().padLeft(2, '0');
          final min = latestDate.minute.toString().padLeft(2, '0');
          _lastSyncTime = '上次同步：$y-$m-$d $h:$min';
        });
      } else {
        OperationLog.instance.action(
          'about_sync_result',
          'dates empty: pull=$pullDate upload=$uploadDate',
        );
      }
    }

    // 后台检查服务器版本
    try {
      final mgr = SyncManager();
      if (mgr.updateManager != null) {
        final results = await mgr.checkUpdates();
        if (!mounted) return;
        for (final r in results) {
          if (r.type == 'qbank') {
            _qbankVersionError = r.checkFailed;
            _serverQbank = r.serverVersion;
            _qbankDownloadReady = r.canDownload;
          }
          if (r.type == 'courses') {
            _coursesVersionError = r.checkFailed;
            _serverCourses = r.serverVersion;
            _coursesDownloadReady = r.canDownload;
          }
          if (r.type == 'user') {
            _userVersionError = r.checkFailed;
            _serverUser = r.serverVersion;
          }
        }
        setState(() => _versionLoaded = true);
        for (final result in results) {
          if (UpdateManager.shouldUpdateSilently(result)) {
            unawaited(_runSilentUpdate(result));
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _versionLoaded = true;
          _qbankVersionError = true;
          _coursesVersionError = true;
          _userVersionError = true;
        });
      }
    }

    if (mounted) setState(() {});
    AuditLogger.instance.page('AboutPage', {'version': appVersion});
  }

  Future<void> _runSilentUpdate(UpdateSummary summary) async {
    try {
      final completed = await SyncManager().runBackgroundUpdate(summary);
      if (!completed || !mounted) return;
      await _load();
      if (mounted) {
        final label = summary.type == 'qbank'
            ? '题库'
            : (summary.type == 'courses' ? '内容数据' : '学习记录');
        AppToast.info(context, '$label已在后台更新');
      }
    } catch (error, stack) {
      AuditLogger.instance.error(
        'AboutPage.background_update.${summary.type}',
        error,
        stack,
      );
      if (mounted) AppToast.warning(context, '后台更新失败，将在下次检查时重试');
    }
  }

  Future<void> _onUpdate(String type) async {
    final label = type == 'qbank'
        ? '题库'
        : (type == 'courses' ? '内容数据' : '学习记录');
    if (type == 'qbank') setState(() => _updatingQbank = true);
    if (type == 'courses') setState(() => _updatingCourses = true);
    if (type == 'user') setState(() => _updatingUser = true);

    Future<void> task(void Function(double) onProgress) =>
        SyncManager().runUpdate(type, onProgress: onProgress);
    final ok = type == 'user'
        ? await showUserSyncProgress(
            context,
            task,
            title: '更新数据',
            message: '正在下载$label新版本…',
          )
        : await showSyncProgress(
            context,
            task,
            title: '更新数据',
            message: '正在下载$label新版本…',
          );

    if (!mounted) return;
    final prefs = AppPrefs();
    var qbankVersion = _localQbank;
    var coursesVersion = _localCourses;
    try {
      qbankVersion = await DatabaseProvider().dataVersion('qbank');
      coursesVersion = await DatabaseProvider().dataVersion('courses');
    } catch (_) {}
    setState(() {
      if (type == 'qbank') {
        _localQbank = qbankVersion;
        _updatingQbank = false;
      }
      if (type == 'courses') {
        _localCourses = coursesVersion;
        _updatingCourses = false;
      }
      if (type == 'user') {
        _localUser = prefs.userVersion;
        _updatingUser = false;
      }
    });
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('关于章鱼智学')),
    body: AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            // ── 品牌标识 ──
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Image.asset('assets/logo_mark.png'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('章鱼智学', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '版本 $appVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _buildSectionLabel('数据与同步'),
            const SizedBox(height: AppSpacing.sm),

            // ── 数据版本卡片 ──
            _buildSectionCard([
              _buildVersionTile(
                icon: Icons.storage,
                label: '题库',
                local: _localQbank,
                server: _serverQbank,
                updating: _updatingQbank,
                downloadReady: _qbankDownloadReady,
                checkFailed: _qbankVersionError,
                onUpdate: () => _onUpdate('qbank'),
              ),
              Divider(height: 1, indent: 48),
              _buildVersionTile(
                icon: Icons.article,
                label: '内容数据',
                local: _localCourses,
                server: _serverCourses,
                updating: _updatingCourses,
                downloadReady: _coursesDownloadReady,
                checkFailed: _coursesVersionError,
                onUpdate: () => _onUpdate('courses'),
              ),
              Divider(height: 1, indent: 48),
              _buildUserTile(),
            ]),
            const SizedBox(height: AppSpacing.md),

            // ── 法律信息 ──
            _buildSectionLabel('应用与支持'),
            const SizedBox(height: AppSpacing.sm),
            _buildSectionCard([
              ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('用户协议'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => launchUrl(
                  Uri.parse('https://zhangyuzhixue.zhtec123.com/terms.html'),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('隐私政策'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => launchUrl(
                  Uri.parse('https://zhangyuzhixue.zhtec123.com/privacy.html'),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.language_outlined),
                title: Text('官方网站'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => launchUrl(Uri.parse('https://zhangyuzhixue.top/')),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('开源许可证'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: '章鱼智学',
                  applicationVersion: appVersion,
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.bug_report_outlined),
                title: Text('导出运行日志'),
                subtitle: Text('用于问题诊断，不包含账号密码'),
                trailing: Icon(Icons.chevron_right),
                onTap: _exportLog,
              ),
            ]),

            const SizedBox(height: AppSpacing.lg),

            Text(
              '© ${DateTime.now().year} 章鱼智学 · 北京',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              '湘ICP备2026008095号-1',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: context.colors.textSecondary),
    ),
  );

  Widget _buildVersionTile({
    required IconData icon,
    required String label,
    required int local,
    required int server,
    required bool updating,
    required bool downloadReady,
    required bool checkFailed,
    required VoidCallback onUpdate,
  }) {
    if (checkFailed) {
      return ListTile(
        leading: Icon(icon, color: context.colors.primary),
        title: Text(label),
        subtitle: Text(
          '检查失败，请稍后重试',
          style: TextStyle(fontSize: 12, color: context.colors.error),
        ),
        trailing: null,
      );
    }
    final hasUpdate = _versionLoaded && server > local;
    final localIsNewer = _versionLoaded && local > server;
    final statusText = !_versionLoaded
        ? '本机 v$local · 正在检查'
        : hasUpdate
        ? downloadReady
              ? '本机 v$local · 最新 v$server'
              : '本机 v$local · 更新暂不可用'
        : localIsNewer
        ? '本机 v$local · 服务器 v$server（本机较新）'
        : '本机 v$local · 已是最新';
    final statusColor = !_versionLoaded
        ? context.colors.textSecondary
        : hasUpdate && downloadReady
        ? context.colors.warning
        : context.colors.success;

    return ListTile(
      leading: Icon(icon, color: context.colors.primary),
      title: Text(label),
      subtitle: Text(
        statusText,
        style: TextStyle(fontSize: 12, color: statusColor),
      ),
      trailing: hasUpdate && downloadReady
          ? ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 80),
              child: AppButton(
                onPressed: updating ? null : onUpdate,
                label: '更新',
                loading: updating,
                type: AppButtonType.outlined,
                size: AppButtonSize.sm,
              ),
            )
          : null,
    );
  }

  Widget _buildUserTile() {
    if (_userVersionError) {
      return ListTile(
        leading: Icon(Icons.devices, color: context.colors.primary),
        title: Text('多设备同步数据'),
        subtitle: Text(
          '检查失败，请稍后重试',
          style: TextStyle(fontSize: 12, color: context.colors.error),
        ),
      );
    }
    final hasUpdate = _serverUser > _localUser;
    return ListTile(
      leading: Icon(Icons.devices, color: context.colors.primary),
      title: Text('多设备同步数据'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_lastSyncTime, style: TextStyle(fontSize: 12)),
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
          ? AppButton(
              onPressed: _updatingUser ? null : () => _onUpdate('user'),
              label: '同步',
              loading: _updatingUser,
              type: AppButtonType.outlined,
              size: AppButtonSize.sm,
              expanded: false,
            )
          : Icon(Icons.check_circle, size: 20, color: context.colors.success),
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
        AppToast.show(
          context,
          icon: Icons.folder_open,
          message: '日志已导出到 Downloads 文件夹',
        );
    }
  }
}
