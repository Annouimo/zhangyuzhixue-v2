import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:shared/debug/operation_log.dart';

import '../data/prefs/app_prefs.dart';
import '../pages/router.dart';

class VideoDeepLink {
  const VideoDeepLink(this.videoId);

  final int videoId;

  String get internalLocation =>
      '${AppRoutes.videoDetail}?videoId=$videoId';

  static VideoDeepLink? parse(Uri uri) {
    if (uri.scheme.toLowerCase() != 'zhangyuzhixue' ||
        uri.host.toLowerCase() != 'video' ||
        uri.pathSegments.length != 1) {
      return null;
    }
    final videoId = int.tryParse(uri.pathSegments.single);
    if (videoId == null || videoId <= 0) return null;
    return VideoDeepLink(videoId);
  }
}

class DeepLinkCoordinator {
  DeepLinkCoordinator._();

  static final DeepLinkCoordinator instance = DeepLinkCoordinator._();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;
  Uri? _lastUri;
  DateTime? _lastHandledAt;

  void start() {
    if (_subscription != null) return;
    _appLinks ??= AppLinks();
    _subscription = _appLinks!.uriLinkStream.listen(
      handle,
      onError: (Object error, StackTrace stack) {
        OperationLog.instance.error('deep_link_stream', error, stack);
      },
    );
  }

  Future<void> handle(Uri uri) async {
    final link = VideoDeepLink.parse(uri);
    if (link == null || _isDuplicate(uri)) {
      if (link == null) {
        OperationLog.instance.action('deep_link_rejected', uri.toString());
      }
      return;
    }
    _lastUri = uri;
    _lastHandledAt = DateTime.now();
    await AppPrefs().setPendingDeepLink(uri.toString());
    if ((AppPrefs().accessToken ?? '').isEmpty) {
      _navigate(AppRoutes.login, replace: true);
      return;
    }
    await consumePending();
  }

  Future<bool> consumePending() async {
    final raw = AppPrefs().pendingDeepLink;
    if (raw == null || (AppPrefs().accessToken ?? '').isEmpty) return false;
    final uri = Uri.tryParse(raw);
    final link = uri == null ? null : VideoDeepLink.parse(uri);
    await AppPrefs().clearPendingDeepLink();
    if (link == null) return false;
    _navigate(link.internalLocation);
    OperationLog.instance.action('deep_link_opened', 'video:${link.videoId}');
    return true;
  }

  bool _isDuplicate(Uri uri) =>
      _lastUri == uri &&
      _lastHandledAt != null &&
      DateTime.now().difference(_lastHandledAt!) < const Duration(seconds: 2);

  void _navigate(String location, {bool replace = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (replace) {
        appRouter.go(location);
      } else {
        appRouter.push(location);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
