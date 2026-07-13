/// App 版本号（单源，从 pubspec.yaml 读取）
///
/// 构建时自动注入：flutter build 时替换 `--dart-define=APP_VERSION=$(cat pubspec.yaml | grep version | head -1 | cut -d' ' -f2)`
/// 本地开发默认值在 pubspec.yaml 中维护。
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '2.0.0');
