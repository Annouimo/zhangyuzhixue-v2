import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/constants/app_version.dart';
import '../../data/update_manager.dart';
import '../../data/database/database_provider.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:url_launcher/url_launcher.dart';

/// 设置页（Tab 2）
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String _serverUrl = 'https://zhangyuzhixue.zhtec123.com';
  int _localQbank = 0;
  int _localCourses = 0;
  int _serverQbank = 0;
  int _serverCourses = 0;
  bool _versionLoaded = false;
  bool _updatingQbank = false;
  bool _updatingCourses = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _localQbank = prefs.getInt('qbank_version') ?? 0;
    _localCourses = prefs.getInt('courses_version') ?? 0;
    setState(() {
      _serverUrl = prefs.getString('server_url') ?? 'https://zhangyuzhixue.zhtec123.com';
    });

    // 后台检查服务器版本
    try {
      final manager = UpdateManager(_serverUrl, DatabaseProvider());
      final results = await manager.checkAll();
      if (!mounted) return;
      for (final r in results) {
        if (r.type == 'qbank') _serverQbank = r.serverVersion;
        if (r.type == 'courses') _serverCourses = r.serverVersion;
      }
    } catch (e) {
      OperationLog.instance.error('SettingsPage._load', e);
    }
    if (mounted) setState(() => _versionLoaded = true);
  }

  bool get _qbankUpdate => _serverQbank > _localQbank;
  bool get _coursesUpdate => _serverCourses > _localCourses;

  /// 是否有待更新（供 HomePage 查询，用于 Tab badge）
  bool get hasPendingUpdates => _qbankUpdate || _coursesUpdate;

  Future<void> _onUpdate(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('server_url') ?? 'https://zhangyuzhixue.zhtec123.com';
    final label = type == 'qbank' ? '题库' : '课程';
    if (type == 'qbank') setState(() => _updatingQbank = true);
    if (type == 'courses') setState(() => _updatingCourses = true);

    await showSyncProgress(
      context,
      (onProgress) async {
        final manager = UpdateManager(baseUrl, DatabaseProvider());
        final results = await manager.checkAll();
        final info = results.firstWhere((r) => r.type == type);
        await manager.downloadAndReplace(
          type: type, url: info.downloadUrl ?? '',
          expectedChecksum: info.checksum ?? '', newVersion: info.serverVersion,
          onProgress: onProgress,
        );
      },
      title: '更新数据',
      message: '正在下载$label新版本…',
    );

    if (!mounted) return;
    final prefs2 = await SharedPreferences.getInstance();
    setState(() {
      if (type == 'qbank') {
        _localQbank = prefs2.getInt('qbank_version') ?? _localQbank;
        _updatingQbank = false;
      }
      if (type == 'courses') {
        _localCourses = prefs2.getInt('courses_version') ?? _localCourses;
        _updatingCourses = false;
      }
    });
  }

  /// 供 HomePage 调用，切换到设置 Tab 时刷新
  void refreshVersions() => _load();

  Future<void> _editServerUrl() async {
    final controller = TextEditingController(text: _serverUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('保存')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', result);
      setState(() => _serverUrl = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        children: [
          _sectionHeader('服务器'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.dns, color: colors.primary),
              title: const Text('服务器地址', style: TextStyle(fontSize: 15)),
              subtitle: Text(_serverUrl, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              trailing: Icon(Icons.edit, size: 16, color: colors.textMuted),
              onTap: _editServerUrl,
            ),
          ]),
          const SizedBox(height: 16),
          _sectionHeader('数据版本'),
          _buildCard([
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
          ]),
          const SizedBox(height: 16),
          _sectionHeader('关于'),
          _buildCard([
            _infoTile(Icons.info_outline, '应用名称', '章鱼智学 · 教师端'),
            _infoTile(Icons.code, '版本', appVersion),
          ]),
          const SizedBox(height: 16),

          // ── 法律信息 ──
          _sectionHeader('法律信息'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('用户协议', style: TextStyle(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrl(Uri.parse('https://zhangyuzhixue.zhtec123.com/terms.html')),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('隐私政策', style: TextStyle(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrl(Uri.parse('https://zhangyuzhixue.zhtec123.com/privacy.html')),
            ),
          ]),
          const SizedBox(height: 24),
          _buildExportLogButton(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
      child: Text(title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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
    final colors = context.colors;
    final hasUpdate = server > local;
    final statusText = !_versionLoaded
        ? 'v$local'
        : hasUpdate
            ? 'v$local → v$server 可用'
            : 'v$local (最新)';
    final statusColor = !_versionLoaded
        ? colors.textSecondary
        : hasUpdate
            ? colors.warning
            : colors.success;

    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: Text(
        statusText,
        style: TextStyle(fontSize: 12, color: statusColor),
      ),
      trailing: hasUpdate
          ? OutlinedButton(
              onPressed: updating ? null : onUpdate,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.warning,
                side: BorderSide(color: colors.warning),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('更新'),
            )
          : null,
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    final colors = context.colors;
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Text(value, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
      dense: true,
    );
  }

  Widget _buildExportLogButton() {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _exportLog,
        icon: const Icon(Icons.bug_report_outlined, size: 16),
        label: const Text('导出运行日志'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _exportLog() async {
    final msg = switch (await OperationLog.instance.exportToShare()) {
      ExportResult.success        => '已打开分享面板',
      ExportResult.fileNotFound   => '暂无日志数据',
      ExportResult.notReady       => '日志已导出到 Downloads 文件夹',
      ExportResult.savedToFolder  => '日志已导出到 Downloads 文件夹',
    };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

