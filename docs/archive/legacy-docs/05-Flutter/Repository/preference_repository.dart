/// 章鱼智学 — PreferenceRepository（本地 DAO 实现）
/// data-db: preference.*
/// 对应页面：preference_welcome.html, preference_list.html, preference_edit.html, profile.html(偏好数)
///
/// 设计说明：
/// - 筛选预设存储于 user.db 的 preference_filter 表
/// - 本地创建/修改后通过同步队列（SyncEntityType.preference）推送到服务端
/// - 登录时 pull_user_db 从服务端 PreferenceFilter 模型恢复数据
///
/// 使用方法：
/// ```dart
/// final repo = PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
/// final list = await repo.getList();        // 获取偏好摘要列表
/// final data = await repo.getEdit(id);      // 获取完整编辑数据
/// final newId = await repo.save(name:..., filter:...);  // 保存（自动入同步队列）
/// await repo.delete(id);                    // 删除（自动入同步队列）
/// ```

class PreferenceFilter {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> types;          // 考试类型（一模/二模/期末）
  final List<String> knowledgeCards;
  final List<String> questionTypes;  // 题型（choice/fill/solution）
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

  /// 序列化为 JSON（供同步队列 payload 使用）
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

/// 本地 DAO 实现，数据源为 user.db preference_filter 表
///
/// 存储格式：
/// - 多值字段（years/regions/conceptTags 等）存储为 JSON 字符串
/// - 如 years="["2025","2024"]"
/// - Repository 层提供 _parseJsonList/_jsonEncode 进行转换
class PreferenceRepository {
  /// 获取偏好摘要列表
  Future<List<PreferenceSummary>> getList() async { /* 委托 PreferenceDao.listAll */ }

  /// 获取偏好计数
  Future<int> getCount() async { /* 委托 PreferenceDao.count */ }

  /// 获取完整编辑数据
  Future<PreferenceEditData> getEdit(int id) async { /* 委托 PreferenceDao.getById */ }

  /// 保存偏好（自动入同步队列 upsert）
  Future<int> save({required String name, required PreferenceFilter filter}) async { /* 委托 PreferenceDao.save + SyncManager.enqueue */ }

  /// 删除偏好（自动入同步队列 delete）
  Future<void> delete(int id) async { /* 委托 PreferenceDao.delete + SyncManager.enqueue */ }
}
