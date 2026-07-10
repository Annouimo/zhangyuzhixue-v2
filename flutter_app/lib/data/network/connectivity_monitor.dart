import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络状态监听器
///
/// 单例，App 启动时 init()，提供实时网络状态流。
class ConnectivityMonitor {
  ConnectivityMonitor._internal();
  static ConnectivityMonitor? _instance;
  factory ConnectivityMonitor() {
    _instance ??= ConnectivityMonitor._internal();
    return _instance!;
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _stateController = StreamController<bool>.broadcast();
  bool _online = true;
  bool _initialized = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 初始化监听
  void init() {
    if (_initialized) return;
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _online = results.any((r) => r != ConnectivityResult.none);
      _stateController.add(_online);
    });
    _initialized = true;
  }

  /// 当前是否在线
  bool get isOnline => _online;

  /// 网络变化流
  Stream<bool> get onConnectivityChanged => _stateController.stream;

  /// 释放资源
  void dispose() {
    _subscription?.cancel();
    _stateController.close();
    _initialized = false;
  }
}
