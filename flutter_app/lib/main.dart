import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/network/connectivity_monitor.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/sync/sync_manager.dart';
import 'package:flutter_app/pages/router.dart'
    show appRouter, routerNavigatorKey;
import 'package:shared/widgets/sync_progress_dialog.dart';
import 'package:flutter_app/widgets/user_sync_progress.dart';
import 'package:shared/widgets/app_toast.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/constants/app_version.dart';
import 'data/sync/update_manager.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局运行时错误捕获
  FlutterError.onError = (details) {
    AuditLogger.instance.error(
      'FlutterError',
      details.exception,
      details.stack,
    );
    OperationLog.instance.error(
      'FlutterError',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AuditLogger.instance.error('PlatformDispatcher', error, stack);
    OperationLog.instance.error('PlatformDispatcher', error, stack);
    return true;
  };

  await AppPrefs().init();
  await AuditLogger.instance.init();
  await OperationLog.instance.init();
  ApiClient().init(baseUrl: appBaseUrl);

  // 注册 token 提供器：所有 API 请求自动携带 Authorization header
  const performanceTestMode = bool.fromEnvironment('PERFORMANCE_TEST_MODE');
  final prefs = AppPrefs();
  setTokenProvider(() => prefs.accessToken);
  setRefreshTokenProvider(() => prefs.refreshToken);
  setOnTokenRefreshed((newAccess, newRefresh) async {
    await prefs.setAccessToken(newAccess);
    if (newRefresh != null) {
      await prefs.setRefreshToken(newRefresh);
    }
  });
  setOnRefreshFailed(() {
    if (performanceTestMode) return;
    prefs.clearAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = routerNavigatorKey.currentContext;
      if (ctx != null) GoRouter.of(ctx).go('/login');
    });
  });
  setOnAuthFailure(() {
    if (performanceTestMode) return;
    prefs.clearAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = routerNavigatorKey.currentContext;
      if (ctx != null) GoRouter.of(ctx).go('/login');
    });
  });

  await DatabaseProvider().init();
  if (!performanceTestMode) {
    ConnectivityMonitor().init();
  }
  final syncApi = SyncApi(ApiClient());
  SyncManager().init(
    SyncQueueDao(DatabaseProvider()),
    syncApi,
    DatabaseProvider(),
  );

  runApp(const ZhangyuzhixueApp());

  // Profile performance journeys use deterministic local fixtures. Network
  // startup work is measured separately and must not add dialogs or mutate the
  // fixture while local regression timings are being collected.
  if (performanceTestMode) return;

  // 启动后推送积压 + 版本检查（不阻塞首帧）
  final updates = await SyncManager().onAppStart();

  // 检查是否有未同步的积压数据
  try {
    final pendingCount = await SyncQueueDao(
      DatabaseProvider(),
    ).getPendingCount();
    if (pendingCount > 0 && updates.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPendingSyncBanner(pendingCount);
      });
    }
  } catch (_) {}

  // 版本检查失败时（updates 为空 + lastCheckError 不为 null）显示连接提示
  if (updates.isEmpty) {
    final checkError = SyncManager().lastCheckError;
    if (checkError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = routerNavigatorKey.currentContext;
        if (ctx == null) return;
        AppToast.warning(ctx, '无法连接服务器，请检查网络');
      });
    }
    return;
  }

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
    if (summary.forceUpdate && summary.canApply) {
      _showForcedUpdateDialog(ctx, summary);
      return; // 一次只处理一个强制更新，完成后再处理下一个
    }
  }

  // 非强制更新 → 显示 banner
  for (final summary in updates) {
    if (summary.canApply &&
        UpdateManager.shouldShowBanner(
          localVersion: summary.localVersion,
          serverVersion: summary.serverVersion,
        )) {
      _showUpdateBanner(ctx, summary);
    }
  }
}

void _showForcedUpdateDialog(BuildContext context, UpdateSummary summary) {
  final label = summary.type == 'qbank'
      ? '题库'
      : (summary.type == 'courses' ? '内容数据' : '学习记录');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(Icons.system_update_rounded, color: ctx.colors.primary),
        title: const Text('数据更新'),
        content: Text(
          summary.message ?? '$label 有新版本（v$summary.serverVersion），请立即更新',
          textAlign: TextAlign.center,
        ),
        actions: [
          AppButton(
            label: '立即更新',
            icon: Icons.download_rounded,
            onPressed: () => _startUpdate(ctx, summary, label),
          ),
        ],
      ),
    ),
  );
}

Future<void> _startUpdate(
  BuildContext context,
  UpdateSummary summary,
  String label,
) async {
  // 关闭当前确认弹窗
  Navigator.of(context).pop();

  // 显示进度弹窗
  Future<void> task(void Function(double) onProgress) =>
      SyncManager().runUpdate(summary.type, onProgress: onProgress);
  final ok = summary.type == 'user'
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
  // 更新成功后显示 Toast
  if (ok && context.mounted) {
    AppToast.success(context, '$label更新完成');
  }
}

void _showUpdateBanner(BuildContext context, UpdateSummary summary) {
  final label = summary.type == 'qbank'
      ? '题库'
      : (summary.type == 'courses' ? '内容数据' : '学习记录');

  AppToast.info(
    context,
    '$label 有新版本（v${summary.serverVersion}）',
    actionLabel: '更新',
    onAction: () => _showForcedUpdateDialog(context, summary),
  );
}

/// 启动后提示有未同步数据
void _showPendingSyncBanner(int count) {
  final ctx = routerNavigatorKey.currentContext;
  if (ctx == null) return;
  AppToast.info(
    ctx,
    '有 $count 条数据等待同步',
    icon: Icons.sync_rounded,
    actionLabel: '查看',
    onAction: () => GoRouter.of(ctx).push('/sync/queue'),
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
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
