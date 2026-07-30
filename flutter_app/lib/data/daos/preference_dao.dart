import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';

/// 筛选方案数据访问层（user 库）
class PreferenceDao {
  final DatabaseProvider _provider;
  PreferenceDao(this._provider);
  db.AppDatabase get _db => _provider.appDb;

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
    String? keyword,
    required String years,
    required String regions,
    required String conceptTags,
    String? types,
    String? knowledgeCards,
    String? questionTypes,
    double? diffMin,
    double? diffMax,
    double? calcMin,
    double? calcMax,
  }) =>
      _db.into(_db.preferenceFilters).insert(db.PreferenceFiltersCompanion(
        name: Value(name),
        keyword: Value(keyword),
        years: Value(years),
        regions: Value(regions),
        conceptTags: Value(conceptTags),
        types: Value(types),
        knowledgeCards: Value(knowledgeCards),
        questionTypes: Value(questionTypes),
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

  /// 更新已有偏好（编辑路径使用）
  Future<void> update({
    required int id,
    required String name,
    String? keyword,
    required String years,
    required String regions,
    required String conceptTags,
    String? types,
    String? knowledgeCards,
    String? questionTypes,
    double? diffMin,
    double? diffMax,
    double? calcMin,
    double? calcMax,
  }) async {
    final q = _db.update(_db.preferenceFilters)..where((t) => t.id.equals(id));
    await q.write(db.PreferenceFiltersCompanion(
      name: Value(name),
      keyword: Value(keyword),
      years: Value(years),
      regions: Value(regions),
      conceptTags: Value(conceptTags),
      types: Value(types),
      knowledgeCards: Value(knowledgeCards),
      questionTypes: Value(questionTypes),
      diffMin: Value(diffMin),
      diffMax: Value(diffMax),
      calcMin: Value(calcMin),
      calcMax: Value(calcMax),
    ));
  }
}
