/// App 版本号 — 从 pubspec.yaml 自动生成
///
/// 由 scripts/release/generate_version.py 自动覆盖。
/// 不要手动编辑。
class AppVersion {
  AppVersion._();
  static const String version = '1.2.0';
  static const int buildNumber = 4;
  static const String releaseChannel = 'beta';
  static const int releaseIteration = 1;
  static const String displayVersion = '1.2.0（公测版 Beta 1）';
}

/// 面向用户显示的版本字符串（自动生成）
const appVersion = AppVersion.displayVersion;

/// API 基础 URL（支持环境切换）
const appBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://zhangyuzhixue.zhtec123.com/api/v1');

/// 服务端根域名
const appServerOrigin =
    String.fromEnvironment('SERVER_ORIGIN', defaultValue: 'https://zhangyuzhixue.zhtec123.com');
