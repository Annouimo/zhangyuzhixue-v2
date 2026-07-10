import 'package:drift/drift.dart';
import '../database/assets_database.dart' as db;

/// 题目数据访问层
class QuestionDao {
  final db.AssetsDatabase _db;
  const QuestionDao(this._db);

  Future<db.QuestionRow?> getById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM questions WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.questions},
    ).get();
    if (rows.isEmpty) return null;
    return _db.questions.map(rows.first.data);
  }

  Future<List<db.QuestionRow>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final ph = ids.map((_) => '?').join(',');
    final rows = await _db.customSelect(
      'SELECT * FROM questions WHERE id IN ($ph)',
      variables: ids.map((i) => Variable(i)).toList(),
      readsFrom: {_db.questions},
    ).get();
    return rows.map((r) => _db.questions.map(r.data)).toList();
  }

  Future<List<db.QuestionRow>> getAll() async {
    final rows = await _db.customSelect(
      'SELECT * FROM questions',
      readsFrom: {_db.questions},
    ).get();
    return rows.map((r) => _db.questions.map(r.data)).toList();
  }

  Future<List<db.QuestionRow>> search({
    List<int>? years,
    List<String>? regions,
    double? diffMin, double? diffMax,
    double? calcMin, double? calcMax,
    String? questionType,
    int? limit,
  }) async {
    final cond = <String>[];
    final args = <dynamic>[];
    if (years != null && years.isNotEmpty) {
      cond.add('year IN (${years.map((_) => '?').join(',')})');
      args.addAll(years);
    }
    if (regions != null && regions.isNotEmpty) {
      cond.add('region IN (${regions.map((_) => '?').join(',')})');
      args.addAll(regions);
    }
    if (diffMin != null) { cond.add('difficulty >= ?'); args.add(diffMin); }
    if (diffMax != null) { cond.add('difficulty <= ?'); args.add(diffMax); }
    if (calcMin != null) { cond.add('calculation >= ?'); args.add(calcMin); }
    if (calcMax != null) { cond.add('calculation <= ?'); args.add(calcMax); }
    if (questionType != null) { cond.add('question_type = ?'); args.add(questionType); }
    var sql = 'SELECT * FROM questions';
    if (cond.isNotEmpty) sql += ' WHERE ${cond.join(' AND ')}';
    if (limit != null) sql += ' LIMIT $limit';
    final rows = await _db.customSelect(
      sql, variables: args.map((a) => Variable(a)).toList(),
      readsFrom: {_db.questions},
    ).get();
    return rows.map((r) => _db.questions.map(r.data)).toList();
  }

  Future<List<int>> getDistinctYears() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT year FROM questions ORDER BY year',
      readsFrom: {_db.questions},
    ).get();
    return rows.map((r) => r.read<int>('year')!).toList();
  }

  Future<List<String>> getDistinctRegions() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT region FROM questions',
      readsFrom: {_db.questions},
    ).get();
    return rows.map((r) => r.read<String>('region')!).toList();
  }

  Future<int> countByType(String type) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM questions WHERE question_type = ?',
      variables: [Variable(type)],
      readsFrom: {_db.questions},
    ).getSingle();
    return row.read<int>('c')!;
  }

  Future<db.ChoiceExtRow?> getChoiceExt(int questionId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM choice_ext WHERE question_id = ?',
      variables: [Variable(questionId)],
      readsFrom: {_db.choiceExt},
    ).get();
    if (rows.isEmpty) return null;
    return _db.choiceExt.map(rows.first.data);
  }

  Future<List<db.SubQuestionRow>> getSubQuestions(int questionId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM sub_questions WHERE question_id = ? ORDER BY sort_order',
      variables: [Variable(questionId)],
      readsFrom: {_db.subQuestions},
    ).get();
    return rows.map((r) => _db.subQuestions.map(r.data)).toList();
  }

  Future<List<db.SolutionMethodRow>> getMethods(int subQuestionId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM solution_methods WHERE sub_question_id = ? ORDER BY sort_order',
      variables: [Variable(subQuestionId)],
      readsFrom: {_db.solutionMethods},
    ).get();
    return rows.map((r) => _db.solutionMethods.map(r.data)).toList();
  }

  Future<List<db.SolutionStepRow>> getSteps(int methodId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM solution_steps WHERE method_id = ? ORDER BY step_number',
      variables: [Variable(methodId)],
      readsFrom: {_db.solutionSteps},
    ).get();
    return rows.map((r) => _db.solutionSteps.map(r.data)).toList();
  }

  Future<List<db.ConceptTagRow>> getTagsByQuestion(int questionId) async {
    final rows = await _db.customSelect(
      'SELECT ct.* FROM concept_tags ct '
      'JOIN question_concept_tags qct ON ct.id = qct.concept_tag_id '
      'WHERE qct.question_id = ?',
      variables: [Variable(questionId)],
      readsFrom: {_db.conceptTags, _db.questionConceptTags},
    ).get();
    return rows.map((r) => _db.conceptTags.map(r.data)).toList();
  }

  Future<List<db.ConceptTagRow>> getAllConceptTags() async {
    final rows = await _db.customSelect(
      'SELECT * FROM concept_tags',
      readsFrom: {_db.conceptTags},
    ).get();
    return rows.map((r) => _db.conceptTags.map(r.data)).toList();
  }

  Future<List<db.KnowledgeCardRow>> getAllKnowledgeCards() async {
    final rows = await _db.customSelect(
      'SELECT * FROM knowledge_cards',
      readsFrom: {_db.knowledgeCards},
    ).get();
    return rows.map((r) => _db.knowledgeCards.map(r.data)).toList();
  }

  Future<db.MetaRow?> getMeta() async {
    final rows = await _db.customSelect(
      'SELECT * FROM meta',
      readsFrom: {_db.meta},
    ).get();
    if (rows.isEmpty) return null;
    return _db.meta.map(rows.first.data);
  }
}
