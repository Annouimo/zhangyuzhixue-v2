import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug/audit_logger.dart';
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
  static const lastSyncTime = 'app_last_sync_time';
  static const pendingHomeworkCount = 'app_pending_homework_count';
  static const pendingAssignments = 'app_pending_assignments';  // JSON 缓存
  static const levelPercentile = 'app_level_percentile';
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

  // ── 用户缓存 ──

  Map<String, dynamic>? get userCache {
    final raw = p.getString(PrefKeys.userCache);
    AuditLogger.instance.prefs('userCache', raw);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      AuditLogger.instance.error('AppPrefs.userCache', e);
      return null;
    }
  }

  Future<bool> setUserCacheStr(String val) => p.setString(PrefKeys.userCache, val);

  // ── 数据库版本 ──

  int get qbankVersion {
    final v = p.getInt(PrefKeys.qbankVersion) ?? 0;
    AuditLogger.instance.prefs(PrefKeys.qbankVersion, v);
    return v;
  }
  Future<bool> setQbankVersion(int v) => p.setInt(PrefKeys.qbankVersion, v);

  int get lectureVersion {
    final v = p.getInt(PrefKeys.lectureVersion) ?? 0;
    AuditLogger.instance.prefs(PrefKeys.lectureVersion, v);
    return v;
  }
  Future<bool> setLectureVersion(int v) => p.setInt(PrefKeys.lectureVersion, v);

  // ── 可访问课程缓存 ──

  List<int> get accessibleCourseIds {
    final raw = p.getString(PrefKeys.accessibleCourses);
    AuditLogger.instance.prefs('accessibleCourseIds', raw);
    if (raw == null) return [];
    try {
      return (raw.split(',')).map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
    } catch (e) {
      AuditLogger.instance.error('AppPrefs.accessibleCourseIds', e);
      return [];
    }
  }

  Future<bool> setAccessibleCourseIds(List<int> ids) =>
      p.setString(PrefKeys.accessibleCourses, ids.join(','));

  // ── 待办作业计数 ──

  int get pendingHomeworkCount {
    final v = p.getInt(PrefKeys.pendingHomeworkCount) ?? 0;
    AuditLogger.instance.prefs(PrefKeys.pendingHomeworkCount, v);
    return v;
  }
  Future<bool> setPendingHomeworkCount(int v) => p.setInt(PrefKeys.pendingHomeworkCount, v);

  // ── 待办作业列表缓存（JSON，用于秒开） ──

  String? get pendingAssignmentsJson => p.getString(PrefKeys.pendingAssignments);
  Future<bool> setPendingAssignmentsJson(String json) =>
      p.setString(PrefKeys.pendingAssignments, json);

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
