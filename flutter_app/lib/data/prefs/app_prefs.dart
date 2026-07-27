import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/debug/audit_logger.dart';
/// 全局 SharedPreferences key 定义
///
/// 命名规范：所有全局 key 以 `app_` 开头。
/// 页面级 key 使用页面缩写前缀（如 `solve_`），在各自页面内定义。
abstract final class PrefKeys {
  static const accessToken = 'app_auth_token';
  static const refreshToken = 'app_refresh_token';
  static const qbankVersion = 'app_qbank_version';
  static const coursesVersion = 'app_courses_version';
  static const lastUpdatePrompt = 'app_last_update_prompt';
  static const ratingCooldownPrefix = 'app_rating_cooldown_';
  static const firstLaunchComplete = 'app_first_launch';
  static const lastSyncTime = 'app_last_sync_time';
  static const levelPercentile = 'app_level_percentile';
  static const userVersion = 'app_user_version';
  static const lastKnownLevel = 'app_last_known_level';
  static const lastKnownUnlockCount = 'app_last_known_unlock_count';
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

  String? get accessToken {
    final v = p.getString(PrefKeys.accessToken);
    AuditLogger.instance.prefs(PrefKeys.accessToken, v);
    return v;
  }
  Future<bool> setAccessToken(String val) => p.setString(PrefKeys.accessToken, val);

  String? get refreshToken {
    final v = p.getString(PrefKeys.refreshToken);
    AuditLogger.instance.prefs(PrefKeys.refreshToken, v);
    return v;
  }
  Future<bool> setRefreshToken(String val) => p.setString(PrefKeys.refreshToken, val);

  // ── 数据库版本 ──

  int get qbankVersion {
    final v = p.getInt(PrefKeys.qbankVersion) ?? 0;
    AuditLogger.instance.prefs(PrefKeys.qbankVersion, v);
    return v;
  }
  Future<bool> setQbankVersion(int v) => p.setInt(PrefKeys.qbankVersion, v);

  int get coursesVersion {
    final v = p.getInt(PrefKeys.coursesVersion) ?? 0;
    AuditLogger.instance.prefs(PrefKeys.coursesVersion, v);
    return v;
  }
  Future<bool> setCoursesVersion(int v) => p.setInt(PrefKeys.coursesVersion, v);

  // ── 等级百分位缓存 ──

  int get levelPercentile => p.getInt(PrefKeys.levelPercentile) ?? 0;
  Future<bool> setLevelPercentile(int v) => p.setInt(PrefKeys.levelPercentile, v);

  // ── 同步时间 ──

  String? get lastSyncTime {
    final v = p.getString(PrefKeys.lastSyncTime);
    AuditLogger.instance.prefs(PrefKeys.lastSyncTime, v);
    return v;
  }
  Future<bool> setLastSyncTime(String label) =>
      p.setString(PrefKeys.lastSyncTime, label);

  // ── 用户数据版本 ──

  int get userVersion {
    final v = p.getInt(PrefKeys.userVersion) ?? 0;
    AuditLogger.instance.prefs(PrefKeys.userVersion, v);
    return v;
  }
  Future<bool> setUserVersion(int v) =>
      p.setInt(PrefKeys.userVersion, v);

  // ── 等级缓存 ──

  int get lastKnownLevel => p.getInt(PrefKeys.lastKnownLevel) ?? 0;
  Future<bool> setLastKnownLevel(int v) =>
      p.setInt(PrefKeys.lastKnownLevel, v);

  // ── 成就缓存 ──

  int get lastKnownUnlockCount => p.getInt(PrefKeys.lastKnownUnlockCount) ?? 0;
  Future<bool> setLastKnownUnlockCount(int v) =>
      p.setInt(PrefKeys.lastKnownUnlockCount, v);

  // ── 更新弹窗冷却 ──

  int? get lastUpdatePromptTimestamp {
    final v = p.getInt(PrefKeys.lastUpdatePrompt);
    AuditLogger.instance.prefs(PrefKeys.lastUpdatePrompt, v);
    return v;
  }
  Future<bool> setLastUpdatePromptTimestamp(int ts) =>
      p.setInt(PrefKeys.lastUpdatePrompt, ts);

  // ── 评价弹窗冷却（Phase 4）──

  /// 判断指定页面的评价弹窗冷却是否活跃（24 小时内）
  bool isRatingCooldownActive(String pageUrl) {
    final ts = p.getInt(PrefKeys.ratingCooldownPrefix + pageUrl);
    AuditLogger.instance.prefs('ratingCooldown_$pageUrl', ts);
    if (ts == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - ts;
    return elapsed < const Duration(hours: 24).inMilliseconds;
  }

  /// 设置评价弹窗冷却时间戳
  Future<bool> setRatingCooldown(String pageUrl) =>
      p.setInt(PrefKeys.ratingCooldownPrefix + pageUrl,
          DateTime.now().millisecondsSinceEpoch);

  // ── 全局共享 key 查询 ──

  /// 判断某个全局 key 是否存在
  bool hasKey(String key) {
    final result = p.containsKey(key);
    AuditLogger.instance.prefs('hasKey($key)', result);
    return result;
  }

  /// 读取整数（通用）
  int getInt(String key, {int defaultValue = 0}) {
    final val = p.getInt(key) ?? defaultValue;
    AuditLogger.instance.prefs('getInt($key)', val);
    return val;
  }

  /// 读取字符串（通用）
  String? getString(String key) {
    final val = p.getString(key);
    AuditLogger.instance.prefs('getString($key)', val);
    return val;
  }

  // ── 清空 ──

  Future<bool> clearAll() => p.clear();
}
