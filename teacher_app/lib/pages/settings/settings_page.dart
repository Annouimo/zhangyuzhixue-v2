import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_theme.dart';
import '../../constants/app_version.dart';

/// 设置页（Tab 2）
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _serverUrl = 'https://zhangyuzhixue.top';
  int _qbankVersion = 0;
  int _coursesVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = prefs.getString('server_url') ?? 'https://zhangyuzhixue.top';
      _qbankVersion = prefs.getInt('qbank_version') ?? 0;
      _coursesVersion = prefs.getInt('courses_version') ?? 0;
    });
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        children: [
          _sectionHeader('服务器'),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.dns, color: AppColors.primary),
              title: const Text('服务器地址', style: TextStyle(fontSize: 15)),
              subtitle: Text(_serverUrl, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.edit, size: 16, color: AppColors.textMuted),
              onTap: _editServerUrl,
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('版本信息'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              _infoTile(Icons.storage, '题库版本', _qbankVersion > 0 ? 'v$_qbankVersion' : '—'),
              _infoTile(Icons.article, '讲义版本', _coursesVersion > 0 ? 'v$_coursesVersion' : '—'),
              _infoTile(Icons.info_outline, '应用名称', '章鱼智学 · 教师端'),
              _infoTile(Icons.code, '版本', appVersion),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
      child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      dense: true,
    );
  }
}
