/// App 版本号（单源，从 pubspec.yaml 读取）
///
/// 构建时自动注入：flutter build 时替换 `--dart-define=APP_VERSION=$(cat pubspec.yaml | grep version | head -1 | cut -d' ' -f2)`
/// 本地开发默认值在 pubspec.yaml 中维护。
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '2.0.0');

/// API 基础 URL（支持环境切换）
///
/// 构建时通过 --dart-define=BASE_URL=https://zhangyuzhixue.top/api/v1 注入。
/// 本地开发默认值指向生产环境。
const appBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://zhangyuzhixue.top/api/v1');

/// 服务端根域名（不含路径，用于构建 PDF URL 等场景）
///
/// 默认从 appBaseUrl 提取协议+主机部分。
const appServerOrigin =
    String.fromEnvironment('SERVER_ORIGIN', defaultValue: 'https://zhangyuzhixue.top');
