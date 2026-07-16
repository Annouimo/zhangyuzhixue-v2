import 'dart:convert';
import '../data/daos/preference_dao.dart';
import 'package:shared/debug/audit_logger.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';


/// 筛选预设 — 委托 PreferenceDao
class PreferenceSummary {
  final int id;
  final String name;
  final String summary;

  const PreferenceSummary({
    required this.id,
    required this.name,
    required this.summary,
  });
}

class PreferenceFilter {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> types;
  final List<String> knowledgeCards;
  final List<String> questionTypes;
  final double? diffMin;
  final double? diffMax;
  final double? calcMin;
  final double? calcMax;

  const PreferenceFilter({
    required this.years,
    required this.regions,
    required this.conceptTags,
    this.types = const [],
    this.knowledgeCards = const [],
    this.questionTypes = const [],
    this.diffMin,
    this.diffMax,
    this.calcMin,
    this.calcMax,
  });

  Map<String, dynamic> toJson() => {
        'years': years,
        'regions': regions,
        'concept_tags': conceptTags,
        if (types.isNotEmpty) 'types': types,
        if (knowledgeCards.isNotEmpty) 'knowledge_cards': knowledgeCards,
        if (questionTypes.isNotEmpty) 'question_types': questionTypes,
        if (diffMin != null) 'diff_min': diffMin,
        if (diffMax != null) 'diff_max': diffMax,
        if (calcMin != null) 'calc_min': calcMin,
        if (calcMax != null) 'calc_max': calcMax,
      };
}

/// 筛选预设编辑数据（含名称）
class PreferenceEditData {
  final String name;
  final PreferenceFilter filter;
  const PreferenceEditData({required this.name, required this.filter});
}

class PreferenceRepository {
  final PreferenceDao _dao;
  const PreferenceRepository(this._dao);

  Future<List<PreferenceSummary>> getList() async {
    final rows = await _dao.listAll();
    return rows.map((r) => PreferenceSummary(
      id: r.id,
      name: r.name,
      summary: _buildSummary(r.years, r.regions, r.conceptTags, r.diffMin, r.diffMax),
    )).toList();
  }

  /// 构建偏好摘要文本，格式：'2025 海淀/东城 · 导数 · 难度 2-8'
  String _buildSummary(String years, String regions, String conceptTags, double? diffMin, double? diffMax) {
    final parts = <String>[];
    final yearStr = _parseJsonList(years).join(' ');
    final regionStr = _parseJsonList(regions).join('/');
    final combined = [yearStr, regionStr].where((s) => s.isNotEmpty).join(' ');
    if (combined.isNotEmpty) parts.add(combined);

    final tags = _parseJsonList(conceptTags);
    if (tags.isNotEmpty) parts.add(tags.join('、'));

    // 只在至少有一个边界非 null 时显示难度范围
    if (diffMin != null || diffMax != null) {
      final min = diffMin?.toStringAsFixed(0) ?? '?';
      final max = diffMax?.toStringAsFixed(0) ?? '?';
      parts.add('难度 $min-$max');
    }

    return parts.join(' · ');
  }

  Future<int> getCount() => _dao.count();

  Future<PreferenceEditData> getEdit(int id) async {
    final row = await _dao.getById(id);
    if (row == null) throw Exception('Preference not found: $id');
    return PreferenceEditData(
      name: row.name,
      filter: PreferenceFilter(
        years: _parseJsonList(row.years),
        regions: _parseJsonList(row.regions),
        conceptTags: _parseJsonList(row.conceptTags),
        types: row.types != null ? _parseJsonList(row.types!) : [],
        knowledgeCards: row.knowledgeCards != null ? _parseJsonList(row.knowledgeCards!) : [],
        questionTypes: row.questionTypes != null ? _parseJsonList(row.questionTypes!) : [],
        diffMin: row.diffMin,
        diffMax: row.diffMax,
        calcMin: row.calcMin,
        calcMax: row.calcMax,
      ),
    );
  }

  /// 保存偏好并加入同步队列。
  ///
  /// 如果 [existingId] 不为 null，则更新已有记录（编辑路径）；
  /// 否则新建记录（新建路径）。返回操作后的本地 ID。
  Future<int> save({
    required String name,
    required PreferenceFilter filter,
    int? existingId,
  }) async {
    final int id;

    if (existingId != null) {
      // 编辑路径：更新已有记录
      await _dao.update(
        id: existingId,
        name: name,
        years: _jsonEncode(filter.years),
        regions: _jsonEncode(filter.regions),
        conceptTags: _jsonEncode(filter.conceptTags),
        types: filter.types.isNotEmpty ? _jsonEncode(filter.types) : null,
        knowledgeCards: filter.knowledgeCards.isNotEmpty ? _jsonEncode(filter.knowledgeCards) : null,
        questionTypes: filter.questionTypes.isNotEmpty ? _jsonEncode(filter.questionTypes) : null,
        diffMin: filter.diffMin,
        diffMax: filter.diffMax,
        calcMin: filter.calcMin,
        calcMax: filter.calcMax,
      );
      id = existingId;
    } else {
      // 新建路径：插入新记录
      id = await _dao.save(
        name: name,
        years: _jsonEncode(filter.years),
        regions: _jsonEncode(filter.regions),
        conceptTags: _jsonEncode(filter.conceptTags),
        types: filter.types.isNotEmpty ? _jsonEncode(filter.types) : null,
        knowledgeCards: filter.knowledgeCards.isNotEmpty ? _jsonEncode(filter.knowledgeCards) : null,
        questionTypes: filter.questionTypes.isNotEmpty ? _jsonEncode(filter.questionTypes) : null,
        diffMin: filter.diffMin,
        diffMax: filter.diffMax,
        calcMin: filter.calcMin,
        calcMax: filter.calcMax,
      );
    }
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.preference,
        operation: SyncOperationType.upsert,
        localId: id,
        payload: jsonEncode({
          'name': name,
          ...filter.toJson(),
        }),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {'type': 'preference_save', 'error': '$e'});
    }
    return id;
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.preference,
        operation: SyncOperationType.delete,
        localId: id,
        payload: '{}',
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {'type': 'preference_delete', 'error': '$e'});
    }
  }

  List<String> _parseJsonList(String raw) {
    if (raw.isEmpty) return [];
    final parsed = jsonDecode(raw);
    if (parsed is! List) return [];
    return parsed.cast<String>();
  }

  String _jsonEncode(List<String> items) => jsonEncode(items);
}
