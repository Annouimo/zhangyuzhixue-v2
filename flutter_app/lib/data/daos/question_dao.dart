import 'package:drift/drift.dart';
import '../database/assets_database.dart' as db;

/// 题目数据访问层
class QuestionDao {
  final db.AssetsDatabase _db;
  const QuestionDao(this._db);

  Future<db.QuestionRow?> getById(int id) async {
    final q = _db.select(_db.questions)..where((t) => t.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<List<db.QuestionRow>> getByIds(List<int> ids) async {
    final q = _db.select(_db.questions)..where((t) => t.id.isIn(ids));
    return q.get();
  }

  Future<List<db.QuestionRow>> getAll() => _db.select(_db.questions).get();

  Future<List<db.QuestionRow>> search({
    List<int>? years, List<String>? regions,
    double? diffMin, double? diffMax,
    double? calcMin, double? calcMax,
    String? questionType, int? limit,
  }) async {
    final q = _db.select(_db.questions);
    if (years != null && years.isNotEmpty) q.where((t) => t.year.isIn(years));
    if (regions != null && regions.isNotEmpty) q.where((t) => t.region.isIn(regions));
    if (diffMin != null) q.where((t) => t.difficulty.isBiggerOrEqual(Variable(diffMin)));
    if (diffMax != null) q.where((t) => t.difficulty.isSmallerOrEqual(Variable(diffMax)));
    if (calcMin != null) q.where((t) => t.calculation.isBiggerOrEqual(Variable(calcMin)));
    if (calcMax != null) q.where((t) => t.calculation.isSmallerOrEqual(Variable(calcMax)));
    if (questionType != null) q.where((t) => t.questionType.equals(questionType));
    if (limit != null) q.limit(limit);
    return q.get();
  }

  Future<List<int>> getDistinctYears() async {
    final all = await _db.select(_db.questions).get();
    final years = all.map((q) => q.year).toSet().toList();
    years.sort();
    return years;
  }

  Future<List<String>> getDistinctRegions() async {
    final all = await _db.select(_db.questions).get();
    return all.map((q) => q.region).toSet().toList();
  }

  Future<int> countByType(String type) async {
    final rows = await (_db.select(_db.questions)
      ..where((t) => t.questionType.equals(type))).get();
    return rows.length;
  }

  Future<db.ChoiceExtRow?> getChoiceExt(int questionId) async {
    final q = _db.select(_db.choiceExt)
      ..where((t) => t.questionId.equals(questionId));
    return q.getSingleOrNull();
  }

  Future<List<db.SubQuestionRow>> getSubQuestions(int questionId) async {
    final q = _db.select(_db.subQuestions)
      ..where((t) => t.questionId.equals(questionId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return q.get();
  }

  Future<List<db.SolutionMethodRow>> getMethods(int subQuestionId) async {
    final q = _db.select(_db.solutionMethods)
      ..where((t) => t.subQuestionId.equals(subQuestionId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return q.get();
  }

  Future<List<db.SolutionStepRow>> getSteps(int methodId) async {
    final q = _db.select(_db.solutionSteps)
      ..where((t) => t.methodId.equals(methodId));
    q.orderBy([(t) => OrderingTerm(expression: t.stepNumber)]);
    return q.get();
  }

  Future<List<db.ConceptTagRow>> getTagsByQuestion(int questionId) async {
    final links = await (_db.select(_db.questionConceptTags)
      ..where((t) => t.questionId.equals(questionId))).get();
    if (links.isEmpty) return [];
    final tagIds = links.map((e) => e.conceptTagId).toList();
    final q = _db.select(_db.conceptTags)..where((t) => t.id.isIn(tagIds));
    return q.get();
  }

  Future<List<db.ConceptTagRow>> getAllConceptTags() =>
      _db.select(_db.conceptTags).get();

  Future<List<db.KnowledgeCardRow>> getAllKnowledgeCards() =>
      _db.select(_db.knowledgeCards).get();

  Future<db.MetaRow?> getMeta() =>
      _db.select(_db.meta).getSingleOrNull();

  Future<List<db.AchievementDefRow>> getAllAchievementDefs() =>
      _db.select(_db.achievementDefs).get();
}
