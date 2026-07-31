import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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
import 'data/sync/foreground_sync_policy.dart';
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
  final updates = (prefs.accessToken ?? '').isEmpty
      ? <UpdateSummary>[]
      : await SyncManager().onAppStart();
  final actionableUpdates = updates
      .where((summary) => summary.hasUpdate && !summary.checkFailed)
      .toList();
  final checkFailed = updates.any((summary) => summary.checkFailed);

  // 检查是否有未同步的积压数据
  try {
    final pendingCount = await SyncQueueDao(
      DatabaseProvider(),
    ).getPendingCount();
    if (pendingCount > 0 && actionableUpdates.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPendingSyncBanner(pendingCount);
      });
    }
  } catch (_) {}

  if (checkFailed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = routerNavigatorKey.currentContext;
      if (ctx == null) return;
      AppToast.warning(ctx, '部分数据更新检查失败，将在网络恢复后重试');
    });
  }

  if (actionableUpdates.isEmpty) return;

  // 首帧渲染后再弹出更新 UI
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _processUpdates(actionableUpdates);
  });
}

final Map<String, int> _promptedUpdateVersions = {};

void _processUpdates(List<UpdateSummary> updates) {
  final ctx = routerNavigatorKey.currentContext;
  if (ctx == null) return;
  updates = updates.where((summary) {
    if (summary.checkFailed || !summary.hasUpdate) return false;
    if (summary.forceUpdate) {
      if (_promptedUpdateVersions[summary.type] == summary.serverVersion) {
        return false;
      }
      _promptedUpdateVersions[summary.type] = summary.serverVersion;
    }
    return true;
  }).toList();

  // 先处理强制更新（优先于 banner）
  for (final summary in updates) {
    if (summary.forceUpdate && summary.canApply) {
      _showForcedUpdateDialog(ctx, summary);
      return; // 一次只处理一个强制更新，完成后再处理下一个
    }
    if (summary.forceUpdate && !summary.canApply) {
      AppToast.warning(ctx, '检测到强制更新，但更新包信息不完整，请稍后重试');
    }
  }

  // 普通更新在后台下载并应用，避免打断当前学习流程。
  for (final summary in updates) {
    if (UpdateManager.shouldUpdateSilently(summary)) {
      _startBackgroundUpdate(summary);
    }
  }
}

void _startBackgroundUpdate(UpdateSummary summary) {
  unawaited(() async {
    try {
      final completed = await SyncManager().runBackgroundUpdate(summary);
      final ctx = routerNavigatorKey.currentContext;
      if (completed && ctx != null && ctx.mounted) {
        final label = summary.type == 'qbank'
            ? '题库'
            : (summary.type == 'courses' ? '内容数据' : '学习记录');
        AppToast.info(ctx, '$label已在后台更新');
      }
    } catch (error, stack) {
      AuditLogger.instance.error(
        'background_update.${summary.type}',
        error,
        stack,
      );
      final ctx = routerNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        AppToast.warning(ctx, '后台更新失败，将在下次检查时重试');
      }
    }
  }());
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

class ZhangyuzhixueApp extends StatefulWidget {
  const ZhangyuzhixueApp({super.key});

  @override
  State<ZhangyuzhixueApp> createState() => _ZhangyuzhixueAppState();
}

class _ZhangyuzhixueAppState extends State<ZhangyuzhixueApp>
    with WidgetsBindingObserver {
  Timer? _userCheckTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  DateTime? _backgroundedAt;
  bool _online = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _online = ConnectivityMonitor().isOnline;
    _connectivitySubscription = ConnectivityMonitor().onConnectivityChanged
        .listen(_onConnectivityChanged);
    _startForegroundTimers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopForegroundTimers();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startForegroundTimers();
      final elapsed = _backgroundedAt == null
          ? Duration.zero
          : DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      unawaited(_syncOnResume(elapsed));
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _backgroundedAt ??= DateTime.now();
      _stopForegroundTimers();
    }
  }

  void _startForegroundTimers() {
    _userCheckTimer ??= Timer.periodic(
      ForegroundSyncPolicy.userCheckInterval,
      (_) => unawaited(_onForegroundTick()),
    );
  }

  void _stopForegroundTimers() {
    _userCheckTimer?.cancel();
    _userCheckTimer = null;
  }

  Future<void> _onForegroundTick() async {
    final lastFullCheck = AppPrefs().lastVersionCheckTime;
    final fullCheckDue = ForegroundSyncPolicy.shouldRunPeriodicFullCheck(
      lastFullCheck,
      DateTime.now(),
    );
    await _coordinate(userOnly: !fullCheckDue);
  }

  Future<void> _syncOnResume(Duration backgroundTime) async {
    if (!_hasSession) return;
    await SyncManager().pushNow();
    if (!ForegroundSyncPolicy.shouldCheckAfterResume(backgroundTime)) return;
    final lastFullCheck = AppPrefs().lastVersionCheckTime;
    final fullCheckDue = ForegroundSyncPolicy.shouldRunFullCheck(
      lastFullCheck,
      DateTime.now(),
    );
    await _coordinate(userOnly: !fullCheckDue);
  }

  void _onConnectivityChanged(bool online) {
    final restored = !_online && online;
    _online = online;
    if (restored && _hasSession) {
      unawaited(_coordinate(userOnly: true, pushFirst: true));
    }
  }

  bool get _hasSession => (AppPrefs().accessToken ?? '').isNotEmpty;

  Future<void> _coordinate({
    bool userOnly = false,
    bool pushFirst = false,
  }) async {
    if (_syncing || !_online || !_hasSession) return;
    _syncing = true;
    try {
      if (pushFirst) await SyncManager().pushNow();
      final updates = userOnly
          ? [await SyncManager().checkUserUpdate()]
          : await SyncManager().checkUpdates();
      if (!mounted) return;
      _processUpdates(updates);
    } catch (error, stack) {
      AuditLogger.instance.error('foreground_sync', error, stack);
    } finally {
      _syncing = false;
    }
  }

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
