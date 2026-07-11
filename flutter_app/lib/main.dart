import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/app_theme.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/network/connectivity_monitor.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/sync/sync_manager.dart';
import 'package:flutter_app/pages/router.dart' show appRouter, routerNavigatorKey;
import 'package:flutter_app/widgets/sync_progress_dialog.dart';
import 'data/sync/update_manager.dart';
import 'data/debug/audit_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPrefs().init();
  await AuditLogger.instance.init();
  ApiClient().init(baseUrl: 'https://zhangyuzhixue.top/api/v1/');

  // 注册 token 提供器：所有 API 请求自动携带 Authorization header
  final prefs = AppPrefs();
  setTokenProvider(() => prefs.accessToken);
  setRefreshTokenProvider(() => prefs.refreshToken);
  setOnTokenRefreshed((newAccess) async {
    await prefs.setAccessToken(newAccess);
  });
  setOnRefreshFailed(() {
    prefs.clearAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = routerNavigatorKey.currentContext;
      if (ctx != null) GoRouter.of(ctx).go('/login');
    });
  });
  setOnAuthFailure(() {
    prefs.clearAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = routerNavigatorKey.currentContext;
      if (ctx != null) GoRouter.of(ctx).go('/login');
    });
  });

  await DatabaseProvider().init();
  ConnectivityMonitor().init();

  final syncApi = SyncApi(ApiClient());
  SyncManager().init(
    SyncQueueDao(DatabaseProvider().appDb),
    syncApi,
    DatabaseProvider(),
  );

  runApp(const ZhangyuzhixueApp());

  // 启动后推送积压 + 版本检查（不阻塞首帧）
  final updates = await SyncManager().onAppStart();

  if (updates.isEmpty) return;

  // 首帧渲染后再弹出更新 UI
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _processUpdates(updates);
  });
}

void _processUpdates(List<UpdateSummary> updates) {
  final ctx = routerNavigatorKey.currentContext;
  if (ctx == null) return;

  // 先处理强制更新（优先于 banner）
  for (final summary in updates) {
    if (summary.forceUpdate) {
      _showForcedUpdateDialog(ctx, summary);
      return; // 一次只处理一个强制更新，完成后再处理下一个
    }
  }

  // 非强制更新 → 显示 banner
  for (final summary in updates) {
    if (UpdateManager.shouldShowBanner(
      localVersion: summary.localVersion,
      serverVersion: summary.serverVersion,
    )) {
      _showUpdateBanner(ctx, summary);
    }
  }
}

void _showForcedUpdateDialog(BuildContext context, UpdateSummary summary) {
  final label = summary.type == 'qbank' ? '题库' : '讲义';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 40, color: Color(0xFF4A6CF7)),
              const SizedBox(height: 12),
              const Text(
                '数据更新',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                summary.message ?? '$label 有新版本（v$summary.serverVersion），请立即更新',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startUpdate(ctx, summary, label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('立即更新', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _startUpdate(BuildContext context, UpdateSummary summary, String label) {
  // 关闭当前确认弹窗
  Navigator.of(context).pop();

  // 显示进度弹窗
  showSyncProgress(
    context,
    (onProgress) async {
      await SyncManager().runUpdate(summary.type, onProgress: onProgress);
    },
  );
}

void _showUpdateBanner(BuildContext context, UpdateSummary summary) {
  final label = summary.type == 'qbank' ? '题库' : '讲义';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label 有新版本（v${summary.serverVersion}）'),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: '更新',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showForcedUpdateDialog(context, summary);
        },
      ),
    ),
  );
}

class ZhangyuzhixueApp extends StatelessWidget {
  const ZhangyuzhixueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '章鱼智学',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
