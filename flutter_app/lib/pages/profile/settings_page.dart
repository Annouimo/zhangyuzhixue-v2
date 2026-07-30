import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../data/api/api_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/daos/sync_queue_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/prefs/app_prefs.dart';
import '../../data/sync/sync_manager.dart';
import '../../domain/auth_repository.dart';
import '../router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _pendingSyncCount;

  @override
  void initState() {
    super.initState();
    _loadSyncState();
  }

  Future<void> _loadSyncState() async {
    try {
      final count = await SyncQueueDao(DatabaseProvider()).getPendingCount();
      if (mounted) setState(() => _pendingSyncCount = count);
    } catch (_) {}
  }

  AuthRepository _authRepository() => AuthRepository(AuthApi(ApiClient()));

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmationController = TextEditingController();
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '当前密码'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码（至少 8 位）'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: confirmationController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '再次输入新密码'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final current = currentController.text;
              final next = newController.text;
              if (current.isNotEmpty &&
                  next.length >= 8 &&
                  next == confirmationController.text) {
                Navigator.pop(dialogContext, (current, next));
              }
            },
            child: const Text('修改密码'),
          ),
        ],
      ),
    );
    currentController.dispose();
    newController.dispose();
    confirmationController.dispose();
    if (values == null || !mounted) return;

    try {
      await _authRepository().changePassword(
        currentPassword: values.$1,
        newPassword: values.$2,
      );
      await SyncManager().onLogout();
      await AppPrefs().clearAll();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      _showError('修改密码失败: $error');
    }
  }

  Future<void> _logout() async {
    final pending = _pendingSyncCount ?? 0;
    final confirmed = await AppDialog.confirm(
      context,
      title: '退出登录？',
      message: pending > 0
          ? '还有 $pending 条数据尚未同步，退出后将丢失。确定退出吗？'
          : '确定要退出当前账号吗？',
      icon: Icons.logout_rounded,
      confirmLabel: '退出',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await _authRepository().logout();
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      if (mounted) _showError('退出失败: $error');
    }
  }

  Future<void> _requestAccountDeletion() async {
    final pending = _pendingSyncCount ?? 0;
    if (pending > 0) {
      _showError('还有 $pending 条数据未同步，请先完成同步再注销账号');
      return;
    }
    final password = await AppDialog.prompt(
      context,
      title: '注销账号',
      message: '提交后账号会立即停用。7 天内可撤销；到期后身份信息将被匿名化。',
      label: '当前密码',
      confirmLabel: '确认注销',
      obscureText: true,
      validator: (value) => value.isEmpty ? '请输入当前密码' : null,
    );
    if (password == null || !mounted) return;

    try {
      await _authRepository().requestAccountDeletion(password);
      await SyncManager().onLogout();
      await DatabaseProvider().clearUserDb();
      await AppPrefs().clearAll();
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      if (mounted) _showError('注销申请失败: $error');
    }
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final syncSubtitle = switch (_pendingSyncCount) {
      null => '正在检查同步状态',
      0 => '数据已同步',
      final count => '$count 条数据待同步',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            const AppSectionHeader(title: '学习与数据'),
            const SizedBox(height: AppSpacing.sm),
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.tune_rounded,
                  title: '我的筛选方案',
                  subtitle: '管理保存的选题条件',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profilePreferences),
                ),
                AppNavigationCard(
                  icon: Icons.sync_rounded,
                  title: '同步状态',
                  subtitle: syncSubtitle,
                  onTap: () => RouterUtils.push(context, AppRoutes.syncQueue),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: '应用与账号'),
            const SizedBox(height: AppSpacing.sm),
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.info_outline_rounded,
                  title: '关于章鱼智学',
                  subtitle: '版本、隐私与开源许可',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profileAbout),
                ),
                AppNavigationCard(
                  icon: Icons.password_rounded,
                  title: '修改密码',
                  subtitle: '验证当前密码后设置新密码',
                  onTap: _changePassword,
                ),
                AppNavigationCard(
                  icon: Icons.person_off_outlined,
                  title: '注销账号',
                  subtitle: '停用账号并进入撤销期限',
                  tone: AppStatusTone.error,
                  onTap: _requestAccountDeletion,
                ),
                AppNavigationCard(
                  icon: Icons.logout_rounded,
                  title: '退出登录',
                  subtitle: '退出当前账号并返回登录页',
                  tone: AppStatusTone.error,
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
