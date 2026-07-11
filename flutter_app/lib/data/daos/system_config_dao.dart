import '../database/assets_database.dart' as db;
import '../debug/audit_logger.dart';

/// 系统配置 DAO（assets.db → system_config 表）
///
/// 提供带缓存 + fallback 默认值的键值查询。
/// 缓存实例生命周期与 AssetsDatabase 一致，DatabaseProvider 重置时自动失效。
class SystemConfigDao {
  final db.AssetsDatabase _db;
  final Map<String, String> _cache = {};

  SystemConfigDao(this._db);

  /// 获取字符串值，不存在时返回 fallback
  Future<String> get(String key, String fallback) async {
    if (_cache.containsKey(key)) return _cache[key]!;
    try {
      final row = await (_db.select(_db.systemConfigs)
        ..where((t) => t.key.equals(key))).getSingleOrNull();
      if (row != null) {
        _cache[key] = row.value;
        return row.value;
      }
    } catch (e) {
      AuditLogger.instance.error('SystemConfigDao.get', e);
      // 查询失败时使用 fallback
    }
    _cache[key] = fallback;
    return fallback;
  }

  /// 获取整数配置值
  Future<int> getInt(String key, int fallback) async {
    final v = await get(key, fallback.toString());
    return int.tryParse(v) ?? fallback;
  }

  /// 获取浮点数配置值
  Future<double> getDouble(String key, double fallback) async {
    final v = await get(key, fallback.toString());
    return double.tryParse(v) ?? fallback;
  }

  /// 清空缓存（assets.db 被替换时调用）
  void clearCache() => _cache.clear();
}
