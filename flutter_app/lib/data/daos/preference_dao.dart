import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 筛选预设数据访问层（user 库）
class PreferenceDao {
  final db.AppDatabase _db;
  const PreferenceDao(this._db);

  Future<List<db.PreferenceFilterRow>> listAll() async {
    final q = _db.select(_db.preferenceFilters)
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return q.get();
  }

  Future<db.PreferenceFilterRow?> getById(int id) async {
    final q = _db.select(_db.preferenceFilters)
      ..where((t) => t.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<int> save({
    required String name,
    required String years,
    required String regions,
    required String conceptTags,
  }) =>
      _db.into(_db.preferenceFilters).insert(db.PreferenceFiltersCompanion(
        name: Value(name),
        years: Value(years),
        regions: Value(regions),
        conceptTags: Value(conceptTags),
      ));

  Future<void> delete(int id) async {
    final q = _db.delete(_db.preferenceFilters)..where((t) => t.id.equals(id));
    await q.go();
  }

  Future<int> count() =>
      _db.select(_db.preferenceFilters).get().then((r) => r.length);
}
