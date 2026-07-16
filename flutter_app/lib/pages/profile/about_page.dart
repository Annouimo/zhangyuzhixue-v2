import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/sync_progress_dialog.dart';
import '../../widgets/shared/app_toast.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/prefs/app_prefs.dart';
import '../../constants/app_version.dart';
import '../../data/debug/audit_logger.dart';
import '../../data/debug/operation_log.dart';

/// 关于页 — 数据版本（题库/课程/用户数据）+ 法律信息
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
    if (ts != null && mounted) {
      setState(() => _lastSyncTime = '上次同步：$ts');
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
      if (mounted) setState(() => _versionLoaded = true);
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
    appBar: AppBar(title: const Text('关于')),
    body: Padding(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      child: Column(children: [
        const SizedBox(height: 32),
        // ── 品牌标识 ──
        const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.school, size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        const Text(
          '章鱼智学',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '版本 $appVersion',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),

        // ── 导出日志按钮 ──
        _buildExportLogButton(),
        const SizedBox(height: 12),

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
          const Divider(height: 1, indent: 48),
          _buildVersionTile(
            icon: Icons.article,
            label: '课程',
            local: _localCourses,
            server: _serverCourses,
            updating: _updatingCourses,
            onUpdate: () => _onUpdate('courses'),
          ),
          const Divider(height: 1, indent: 48),
          _buildUserTile(),
        ]),
        const SizedBox(height: 12),

        // ── 法律信息 ──
        _buildSectionCard([
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('用户协议', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppToast.show(context, icon: Icons.description, message: '用户协议页面即将上线'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私政策', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppToast.show(context, icon: Icons.description, message: '隐私政策页面即将上线'),
          ),
        ]),

        const Spacer(),
        Text(
          '© ${DateTime.now().year} 章鱼智学 · 北京',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
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
    final hasUpdate = server > local;
    final statusText = !_versionLoaded
        ? 'v$local'
        : hasUpdate
            ? 'v$local → v$server 可用'
            : 'v$local (最新)';
    final statusColor = !_versionLoaded
        ? AppColors.textSecondary
        : hasUpdate
            ? AppColors.warning
            : AppColors.success;

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: Text(
        statusText,
        style: TextStyle(fontSize: 12, color: statusColor),
      ),
      trailing: hasUpdate
          ? OutlinedButton(
              onPressed: updating ? null : onUpdate,
              child: updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('更新'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildUserTile() {
    final hasUpdate = _serverUser > _localUser;
    return ListTile(
      leading: const Icon(Icons.sync, color: AppColors.primary),
      title: const Text('用户数据', style: TextStyle(fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lastSyncTime,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '从云端恢复数据到本机',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            '日常记录已自动同步',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            !_versionLoaded
                ? ''
                : hasUpdate
                    ? '检测到服务器有新数据，建议更新'
                    : '',
            style: TextStyle(fontSize: 11, color: hasUpdate ? AppColors.warning : Colors.transparent),
          ),
        ],
      ),
      trailing: !_versionLoaded
          ? null
          : hasUpdate
              ? OutlinedButton(
                  onPressed: _updatingUser ? null : () => _onUpdate('user'),
                  child: _updatingUser
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('更新'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : const Icon(Icons.check_circle, size: 20, color: AppColors.success),
    );
  }

  /// ── 导出日志按钮 ──
  Widget _buildExportLogButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _exportLog,
        icon: const Icon(Icons.bug_report_outlined, size: 16),
        label: const Text('导出运行日志'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _exportLog() async {
    final path = await OperationLog.instance.exportToShare();
    if (!mounted) return;
    if (path != null) {
      AppToast.show(context, icon: Icons.check_circle, message: '日志已导出，可通过微信发送');
    } else {
      AppToast.show(context, icon: Icons.warning, message: '暂无日志数据');
    }
  }
}
