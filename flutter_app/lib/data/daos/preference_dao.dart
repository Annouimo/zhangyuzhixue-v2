import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../debug/audit_logger.dart';

/// 筛选预设数据访问层（user 库）
class PreferenceDao {
  final db.AppDatabase _db;
  const PreferenceDao(this._db);

  Future<List<db.PreferenceFilterRow>> listAll() async {
    final q = _db.select(_db.preferenceFilters)
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    final rows = await q.get();
    AuditLogger.instance.dao('PreferenceDao.listAll', rows.length, {});
    return rows;
  }

  Future<db.PreferenceFilterRow?> getById(int id) async {
    final q = _db.select(_db.preferenceFilters)
      ..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('PreferenceDao.getById', result != null ? 1 : 0, {'id': id});
    return result;
  }

  Future<int> save({
    required String name,
    required String years,
    required String regions,
    required String conceptTags,
    String? types,
    double? diffMin,
    double? diffMax,
    double? calcMin,
    double? calcMax,
  }) =>
      _db.into(_db.preferenceFilters).insert(db.PreferenceFiltersCompanion(
        name: Value(name),
        years: Value(years),
        regions: Value(regions),
        conceptTags: Value(conceptTags),
        types: Value(types),
        diffMin: Value(diffMin),
        diffMax: Value(diffMax),
        calcMin: Value(calcMin),
        calcMax: Value(calcMax),
      ));

  Future<void> delete(int id) async {
    final q = _db.delete(_db.preferenceFilters)..where((t) => t.id.equals(id));
    await q.go();
  }

  Future<int> count() async {
    final rows = await _db.select(_db.preferenceFilters).get();
    AuditLogger.instance.dao('PreferenceDao.count', rows.length, {});
    return rows.length;
  }
}
