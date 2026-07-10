// 版本检查 + .db 下载 + 替换（预留）

/// 检查是否需要强制更新
bool shouldForceUpdate({
  required int localVersion,
  required int serverVersion,
  required bool serverForceUpdate,
}) {
  return serverForceUpdate || (serverVersion - localVersion >= 3);
}

/// 判断是否显示更新横幅
bool shouldShowBanner({
  required int localVersion,
  required int serverVersion,
}) {
  return serverVersion > localVersion;
}
