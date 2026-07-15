import 'package:drift/drift.dart';
import '../database/assets_database.dart' as db;

/// 题目数据访问层（教师端，无 AuditLogger）
class QuestionDao {
  final db.AssetsDatabase _db;
  const QuestionDao(this._db);

  Future<db.QuestionRow?> getById(int id) async {
    final q = _db.select(_db.questions)..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    return result;
  }

  Future<List<db.QuestionRow>> getByIds(List<int> ids) async {
    final q = _db.select(_db.questions)..where((t) => t.id.isIn(ids));
    final rows = await q.get();
    return rows;
  }

  Future<List<db.QuestionRow>> getAll() async {
    final rows = await _db.select(_db.questions).get();
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

    return rows;
  }

  Future<List<int>> getDistinctYears() async {
    final all = await _db.select(_db.questions).get();
    final years = all.map((q) => q.year).toSet().toList();
    years.sort();
    return years;
  }

  Future<List<String>> getDistinctRegions() async {
    final all = await _db.select(_db.questions).get();
    final regions = all.map((q) => q.region).toSet().toList();
    return regions;
  }

  Future<List<String>> getDistinctExamTypes() async {
    final all = await _db.select(_db.questions).get();
    final types = all.map((q) => q.examType).toSet().toList()..sort();
    return types;
  }

  Future<int> countByType(String type) async {
    final rows = await (_db.select(_db.questions)
      ..where((t) => t.questionType.equals(type))).get();
    return rows.length;
  }

  Future<db.ChoiceExtRow?> getChoiceExt(int questionId) async {
    final q = _db.select(_db.choiceExt)
      ..where((t) => t.questionId.equals(questionId));
    final result = await q.getSingleOrNull();
    return result;
  }

  Future<List<db.SubQuestionRow>> getSubQuestions(int questionId) async {
    final q = _db.select(_db.subQuestions)
      ..where((t) => t.questionId.equals(questionId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    return rows;
  }

  Future<List<db.SolutionMethodRow>> getMethods(int subQuestionId) async {
    final q = _db.select(_db.solutionMethods)
      ..where((t) => t.subQuestionId.equals(subQuestionId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    return rows;
  }

  Future<List<db.SolutionStepRow>> getSteps(int methodId) async {
    final q = _db.select(_db.solutionSteps)
      ..where((t) => t.methodId.equals(methodId));
    q.orderBy([(t) => OrderingTerm(expression: t.stepNumber)]);
    final rows = await q.get();
    return rows;
  }

  /// 批量查询多个方法的步骤（替代 N+1 循环）
  Future<List<db.SolutionStepRow>> getStepsByMethodIds(List<int> methodIds) async {
    if (methodIds.isEmpty) return [];
    final q = _db.select(_db.solutionSteps)
      ..where((t) => t.methodId.isIn(methodIds));
    q.orderBy([(t) => OrderingTerm(expression: t.stepNumber)]);
    final rows = await q.get();
    return rows;
  }

  /// 批量查询多个子题的所有解法（替代 N+1 循环）
  Future<List<db.SolutionMethodRow>> getMethodsBySubQuestionIds(List<int> subQuestionIds) async {
    if (subQuestionIds.isEmpty) return [];
    final q = _db.select(_db.solutionMethods)
      ..where((t) => t.subQuestionId.isIn(subQuestionIds));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    return rows;
  }

  /// 一次读取全部 question_concept_tag 链接，返回 [questionId, conceptTagId] 行
  Future<List<db.QuestionConceptTagRow>> getAllQuestionTagLinks() async {
    final rows = await _db.select(_db.questionConceptTags).get();
    return rows;
  }

  Future<List<db.ConceptTagRow>> getTagsByQuestion(int questionId) async {
    final links = await (_db.select(_db.questionConceptTags)
      ..where((t) => t.questionId.equals(questionId))).get();
    if (links.isEmpty) return [];
    final tagIds = links.map((e) => e.conceptTagId).toList();
    final q = _db.select(_db.conceptTags)..where((t) => t.id.isIn(tagIds));
    final rows = await q.get();
    return rows;
  }

  Future<List<db.ConceptTagRow>> getAllConceptTags() async {
    final rows = await _db.select(_db.conceptTags).get();
    return rows;
  }

  Future<List<db.KnowledgeCardRow>> getAllKnowledgeCards() async {
    final rows = await _db.select(_db.knowledgeCards).get();
    return rows;
  }

  Future<db.KnowledgeCardRow?> getKnowledgeCardByTitle(String title) async {
    final q = _db.select(_db.knowledgeCards)
      ..where((t) => t.title.equals(title));
    final result = await q.getSingleOrNull();
    return result;
  }

  Future<db.MetaRow?> getMeta() async {
    final row = await _db.select(_db.meta).getSingleOrNull();
    return row;
  }
}
