import 'package:drift/drift.dart';
import '../database/database_provider.dart';
import '../database/assets_database.dart' as db;
import '../debug/audit_logger.dart';

/// 题目数据访问层
class QuestionDao {
  final DatabaseProvider _provider;
  QuestionDao(this._provider);
  db.AssetsDatabase get _db => _provider.assetsDb;

  Future<db.QuestionRow?> getById(int id) async {
    final q = _db.select(_db.questions)..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('QuestionDao.getById', result != null ? 1 : 0, {'id': id});
    return result;
  }

  Future<List<db.QuestionRow>> getByIds(List<int> ids) async {
    final q = _db.select(_db.questions)..where((t) => t.id.isIn(ids));
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getByIds', rows.length, {'idsCount': ids.length});
    return rows;
  }

  Future<List<db.QuestionRow>> getAll() async {
    final rows = await _db.select(_db.questions).get();
    AuditLogger.instance.dao('QuestionDao.getAll', rows.length, {});
    return rows;
  }

  Future<List<db.QuestionRow>> search({
    List<int>? years, List<String>? regions,
    double? diffMin, double? diffMax,
    double? calcMin, double? calcMax,
    String? questionType, int? limit,
    List<String>? conceptTagNames, List<String>? knowledgeCardNames,
    List<String>? examTypes, List<String>? questionTypes,
  }) async {
    final q = _db.select(_db.questions);
    if (years != null && years.isNotEmpty) q.where((t) => t.year.isIn(years));
    if (regions != null && regions.isNotEmpty) q.where((t) => t.region.isIn(regions));
    if (diffMin != null) q.where((t) => t.difficulty.isBiggerOrEqual(Variable(diffMin)));
    if (diffMax != null) q.where((t) => t.difficulty.isSmallerOrEqual(Variable(diffMax)));
    if (calcMin != null) q.where((t) => t.calculation.isBiggerOrEqual(Variable(calcMin)));
    if (calcMax != null) q.where((t) => t.calculation.isSmallerOrEqual(Variable(calcMax)));
    if (questionType != null) q.where((t) => t.questionType.equals(questionType));
    if (questionTypes != null && questionTypes.isNotEmpty) q.where((t) => t.questionType.isIn(questionTypes));
    if (examTypes != null && examTypes.isNotEmpty) q.where((t) => t.examType.isIn(examTypes));
    if (limit != null) q.limit(limit);
    var rows = await q.get();

    // 内存过滤：概念标签
    if (conceptTagNames != null && conceptTagNames.isNotEmpty) {
      final tagRows = _db.select(_db.conceptTags)
        ..where((t) => t.name.isIn(conceptTagNames));
      final tagIds = (await tagRows.get()).map((t) => t.id).toSet();
      if (tagIds.isNotEmpty) {
        final links = await (_db.select(_db.questionConceptTags)
          ..where((t) => t.conceptTagId.isIn(tagIds))).get();
        final questionIds = links.map((l) => l.questionId).toSet();
        rows = rows.where((r) => questionIds.contains(r.id)).toList();
      } else {
        return []; // 选中的概念标签在 DB 中不存在 → 空结果
      }
    }

    // 内存过滤：知识卡片
    if (knowledgeCardNames != null && knowledgeCardNames.isNotEmpty) {
      final kcRows = _db.select(_db.knowledgeCards)
        ..where((t) => t.title.isIn(knowledgeCardNames));
      final kcIds = (await kcRows.get()).map((k) => k.id).toSet();
      if (kcIds.isNotEmpty) {
        final links = await (_db.select(_db.questionKnowledgeCards)
          ..where((t) => t.knowledgeCardId.isIn(kcIds))).get();
        final questionIds = links.map((l) => l.questionId).toSet();
        rows = rows.where((r) => questionIds.contains(r.id)).toList();
      } else {
        return [];
      }
    }

    AuditLogger.instance.dao('QuestionDao.search', rows.length, {
      'years': years?.length, 'regions': regions?.length,
      'diffMin': diffMin, 'diffMax': diffMax,
      'questionType': questionType, 'questionTypes': questionTypes?.length,
      'conceptTags': conceptTagNames?.length, 'knowledgeCards': knowledgeCardNames?.length,
    });
    return rows;
  }

  Future<List<int>> getDistinctYears() async {
    final all = await _db.select(_db.questions).get();
    final years = all.map((q) => q.year).toSet().toList();
    years.sort();
    AuditLogger.instance.dao('QuestionDao.getDistinctYears', years.length, {});
    return years;
  }

  Future<List<String>> getDistinctRegions() async {
    final all = await _db.select(_db.questions).get();
    final regions = all.map((q) => q.region).toSet().toList();
    AuditLogger.instance.dao('QuestionDao.getDistinctRegions', regions.length, {});
    return regions;
  }

  Future<List<String>> getDistinctExamTypes() async {
    final all = await _db.select(_db.questions).get();
    final types = all.map((q) => q.examType).toSet().toList()..sort();
    AuditLogger.instance.dao('QuestionDao.getDistinctExamTypes', types.length, {});
    return types;
  }

  Future<int> countByType(String type) async {
    final rows = await (_db.select(_db.questions)
      ..where((t) => t.questionType.equals(type))).get();
    AuditLogger.instance.dao('QuestionDao.countByType', rows.length, {'type': type});
    return rows.length;
  }

  Future<db.ChoiceExtRow?> getChoiceExt(int questionId) async {
    final q = _db.select(_db.choiceExt)
      ..where((t) => t.questionId.equals(questionId));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('QuestionDao.getChoiceExt', result != null ? 1 : 0, {'questionId': questionId});
    return result;
  }

  Future<List<db.SubQuestionRow>> getSubQuestions(int questionId) async {
    final q = _db.select(_db.subQuestions)
      ..where((t) => t.questionId.equals(questionId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getSubQuestions', rows.length, {'questionId': questionId});
    return rows;
  }

  Future<List<db.SolutionMethodRow>> getMethods(int subQuestionId) async {
    final q = _db.select(_db.solutionMethods)
      ..where((t) => t.subQuestionId.equals(subQuestionId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getMethods', rows.length, {'subQuestionId': subQuestionId});
    return rows;
  }

  Future<List<db.SolutionStepRow>> getSteps(int methodId) async {
    final q = _db.select(_db.solutionSteps)
      ..where((t) => t.methodId.equals(methodId));
    q.orderBy([(t) => OrderingTerm(expression: t.stepNumber)]);
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getSteps', rows.length, {'methodId': methodId});
    return rows;
  }

  /// 批量查询多个方法的步骤（替代 N+1 循环）
  Future<List<db.SolutionStepRow>> getStepsByMethodIds(List<int> methodIds) async {
    if (methodIds.isEmpty) return [];
    final q = _db.select(_db.solutionSteps)
      ..where((t) => t.methodId.isIn(methodIds));
    q.orderBy([(t) => OrderingTerm(expression: t.stepNumber)]);
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getStepsByMethodIds', rows.length, {'methodIdsCount': methodIds.length});
    return rows;
  }

  /// 批量查询多个子题的所有解法（替代 N+1 循环）
  Future<List<db.SolutionMethodRow>> getMethodsBySubQuestionIds(List<int> subQuestionIds) async {
    if (subQuestionIds.isEmpty) return [];
    final q = _db.select(_db.solutionMethods)
      ..where((t) => t.subQuestionId.isIn(subQuestionIds));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getMethodsBySubQuestionIds', rows.length, {'subQuestionIdsCount': subQuestionIds.length});
    return rows;
  }

  /// 一次读取全部 question_concept_tag 链接，返回 [questionId, conceptTagId] 行
  Future<List<db.QuestionConceptTagRow>> getAllQuestionTagLinks() async {
    final rows = await _db.select(_db.questionConceptTags).get();
    AuditLogger.instance.dao('QuestionDao.getAllQuestionTagLinks', rows.length, {});
    return rows;
  }

  Future<List<db.ConceptTagRow>> getTagsByQuestion(int questionId) async {
    final links = await (_db.select(_db.questionConceptTags)
      ..where((t) => t.questionId.equals(questionId))).get();
    if (links.isEmpty) return [];
    final tagIds = links.map((e) => e.conceptTagId).toList();
    final q = _db.select(_db.conceptTags)..where((t) => t.id.isIn(tagIds));
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getTagsByQuestion', rows.length, {'questionId': questionId});
    return rows;
  }

  Future<List<db.ConceptTagRow>> getAllConceptTags() async {
    final rows = await _db.select(_db.conceptTags).get();
    AuditLogger.instance.dao('QuestionDao.getAllConceptTags', rows.length, {});
    return rows;
  }

  Future<List<db.KnowledgeCardRow>> getKnowledgeCardsByQuestion(int questionId) async {
    final links = await (_db.select(_db.questionKnowledgeCards)
      ..where((t) => t.questionId.equals(questionId))).get();
    if (links.isEmpty) return [];
    final kcIds = links.map((e) => e.knowledgeCardId).toList();
    final q = _db.select(_db.knowledgeCards)..where((t) => t.id.isIn(kcIds));
    final rows = await q.get();
    AuditLogger.instance.dao('QuestionDao.getKnowledgeCardsByQuestion', rows.length, {'questionId': questionId});
    return rows;
  }

  Future<List<db.KnowledgeCardRow>> getAllKnowledgeCards() async {
    final rows = await _db.select(_db.knowledgeCards).get();
    AuditLogger.instance.dao('QuestionDao.getAllKnowledgeCards', rows.length, {});
    return rows;
  }

  Future<db.KnowledgeCardRow?> getKnowledgeCardByTitle(String title) async {
    final q = _db.select(_db.knowledgeCards)
      ..where((t) => t.title.equals(title));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('QuestionDao.getKnowledgeCardByTitle', result != null ? 1 : 0, {'title': title});
    return result;
  }

  Future<db.MetaRow?> getMeta() async {
    final row = await _db.select(_db.meta).getSingleOrNull();
    AuditLogger.instance.dao('QuestionDao.getMeta', row != null ? 1 : 0, {});
    return row;
  }
}
