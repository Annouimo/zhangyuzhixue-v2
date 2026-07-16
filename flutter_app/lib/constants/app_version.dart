/// App 版本号（自动生成 — 不要手动修改）
///
/// 来源: pubspec.yaml 中的 version 字段
/// 生成命令: python scripts/generate_version.py
const appVersion = '1.0.0-alpha.2+1';

/// API 基础 URL（支持环境切换）
const appBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://zhangyuzhixue.top/api/v1');

/// 服务端根域名
const appServerOrigin =
    String.fromEnvironment('SERVER_ORIGIN', defaultValue: 'https://zhangyuzhixue.top');
