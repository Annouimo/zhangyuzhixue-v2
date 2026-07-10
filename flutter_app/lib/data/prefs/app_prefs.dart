import 'package:shared_preferences/shared_preferences.dart';

/// 全局 SharedPreferences key 定义
///
/// 命名规范：所有全局 key 以 `app_` 开头。
/// 页面级 key 使用页面缩写前缀（如 `solve_`），在各自页面内定义。
abstract final class PrefKeys {
  static const accessToken = 'app_auth_token';
  static const refreshToken = 'app_refresh_token';
  static const userCache = 'app_user_cache';
  static const qbankVersion = 'app_qbank_version';
  static const lectureVersion = 'app_lecture_version';
  static const accessibleCourses = 'app_accessible_courses';
  static const lastUpdatePrompt = 'app_last_update_prompt';
  static const ratingCooldownPrefix = 'app_rating_cooldown_';
  static const firstLaunchComplete = 'app_first_launch';
}

/// SharedPreferences 封装层
///
/// 仅管理全局级别 key（`app_` 前缀），页面级 key 由各页面自行管理。
/// 单例模式——SharedPreferences 实例在 App 启动时加载一次。
class AppPrefs {
  AppPrefs._internal();
  static AppPrefs? _instance;
  factory AppPrefs() {
    _instance ??= AppPrefs._internal();
    return _instance!;
  }

  SharedPreferences? _prefs;

  /// 必须在 App 启动时调用一次
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get p {
    if (_prefs == null) {
      throw StateError('AppPrefs not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ── Token ──

  String? get accessToken => p.getString(PrefKeys.accessToken);
  Future<bool> setAccessToken(String val) => p.setString(PrefKeys.accessToken, val);

  String? get refreshToken => p.getString(PrefKeys.refreshToken);
  Future<bool> setRefreshToken(String val) => p.setString(PrefKeys.refreshToken, val);

  // ── 用户缓存 ──

  Map<String, dynamic>? get userCache {
    final raw = p.getString(PrefKeys.userCache);
    if (raw == null) return null;
    try {
      // JSON decode handled by caller — stored as raw string
      return Map<String, dynamic>.from(
        // ignore: avoid_dynamic_calls
        (Uri.tryParse(raw)?.queryParametersAll ?? <String, List<String>>{}).map(
          (k, v) => MapEntry(k, v.first as dynamic),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> setUserCacheStr(String val) => p.setString(PrefKeys.userCache, val);

  // ── 数据库版本 ──

  int get qbankVersion => p.getInt(PrefKeys.qbankVersion) ?? 0;
  Future<bool> setQbankVersion(int v) => p.setInt(PrefKeys.qbankVersion, v);

  int get lectureVersion => p.getInt(PrefKeys.lectureVersion) ?? 0;
  Future<bool> setLectureVersion(int v) => p.setInt(PrefKeys.lectureVersion, v);

  // ── 可访问课程缓存 ──

  List<int> get accessibleCourseIds {
    final raw = p.getString(PrefKeys.accessibleCourses);
    if (raw == null) return [];
    try {
      return (raw.split(',')).map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> setAccessibleCourseIds(List<int> ids) =>
      p.setString(PrefKeys.accessibleCourses, ids.join(','));

  // ── 更新弹窗冷却 ──

  int? get lastUpdatePromptTimestamp => p.getInt(PrefKeys.lastUpdatePrompt);
  Future<bool> setLastUpdatePromptTimestamp(int ts) =>
      p.setInt(PrefKeys.lastUpdatePrompt, ts);

  // ── 全局共享 key 查询 ──

  /// 判断某个全局 key 是否存在
  bool hasKey(String key) => p.containsKey(key);

  /// 读取整数（通用）
  int getInt(String key, {int defaultValue = 0}) => p.getInt(key) ?? defaultValue;

  /// 读取字符串（通用）
  String? getString(String key) => p.getString(key);

  // ── 清空 ──

  Future<bool> clearAll() => p.clear();
}
