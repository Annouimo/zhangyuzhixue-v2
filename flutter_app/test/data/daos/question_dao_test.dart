import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/assets_database.dart' as db;
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/database/database_provider.dart';

void main() {
  late db.AssetsDatabase database;
  late QuestionDao dao;

  setUp(() {
    database = db.AssetsDatabase(NativeDatabase.memory());
    DatabaseProvider().setAssetsDbForTesting(database);
    dao = QuestionDao(DatabaseProvider());
  });

  tearDown(() => database.close());

  // Helper to insert test question
  Future<int> insertQuestion({
    int year = 2024,
    String examType = '一模',
    String region = '海淀',
    String number = '17',
    String questionType = 'choice',
    double difficulty = 5.0,
    double calculation = 5.0,
    String stem = '题目正文',
  }) async {
    return database.into(database.questions).insert(db.QuestionsCompanion(
      year: Value(year),
      examType: Value(examType),
      region: Value(region),
      number: Value(number),
      questionType: Value(questionType),
      difficulty: Value(difficulty),
      calculation: Value(calculation),
      stem: Value(stem),
    ));
  }

  group('QuestionDao', () {
    test('getById returns null for nonexistent', () async {
      expect(await dao.getById(999), isNull);
    });

    test('getById returns inserted question', () async {
      final id = await insertQuestion();
      final result = await dao.getById(id);
      expect(result, isNotNull);
      expect(result!.stem, '题目正文');
      expect(result.year, 2024);
    });

    test('getAll returns all questions', () async {
      await insertQuestion();
      await insertQuestion(year: 2023);
      final all = await dao.getAll();
      expect(all.length, 2);
    });

    test('getByIds returns matching questions', () async {
      final id1 = await insertQuestion();
      await insertQuestion();
      final id2 = await insertQuestion();
      final result = await dao.getByIds([id1, id2]);
      expect(result.length, 2);
    });

    test('search filters by year', () async {
      await insertQuestion(year: 2024);
      await insertQuestion(year: 2025);
      final result = await dao.search(years: [2024]);
      expect(result.length, 1);
      expect(result.first.year, 2024);
    });

    test('search filters by region', () async {
      await insertQuestion(region: '海淀');
      await insertQuestion(region: '西城');
      final result = await dao.search(regions: ['海淀']);
      expect(result.length, 1);
    });

    test('search filters by question type', () async {
      await insertQuestion(questionType: 'choice');
      await insertQuestion(questionType: 'solution');
      final result = await dao.search(questionType: 'solution');
      expect(result.length, 1);
    });

    test('search filters by difficulty range', () async {
      await insertQuestion(difficulty: 3.0);
      await insertQuestion(difficulty: 7.0);
      final result = await dao.search(diffMin: 5.0);
      expect(result.length, 1);
    });

    test('search with multiple filters', () async {
      await insertQuestion(year: 2024, region: '海淀', difficulty: 5.0);
      await insertQuestion(year: 2025, region: '西城', difficulty: 7.0);
      final result = await dao.search(years: [2024], regions: ['海淀']);
      expect(result.length, 1);
    });

    test('search respects limit', () async {
      await insertQuestion();
      await insertQuestion();
      await insertQuestion();
      final result = await dao.search(limit: 2);
      expect(result.length, 2);
    });

    test('getDistinctYears returns sorted', () async {
      await insertQuestion(year: 2025);
      await insertQuestion(year: 2024);
      await insertQuestion(year: 2024);
      final years = await dao.getDistinctYears();
      expect(years, [2024, 2025]);
    });

    test('getDistinctRegions returns unique', () async {
      await insertQuestion(region: '海淀');
      await insertQuestion(region: '海淀');
      await insertQuestion(region: '西城');
      final regions = await dao.getDistinctRegions();
      expect(regions, containsAll(['海淀', '西城']));
      expect(regions.length, 2);
    });

    test('countByType returns correct count', () async {
      await insertQuestion(questionType: 'choice');
      await insertQuestion(questionType: 'choice');
      await insertQuestion(questionType: 'solution');
      expect(await dao.countByType('choice'), 2);
      expect(await dao.countByType('solution'), 1);
    });

    test('getSubQuestions returns sorted', () async {
      final qId = await insertQuestion();
      await database.into(database.subQuestions).insert(db.SubQuestionsCompanion(
        questionId: Value(qId), sortOrder: Value(2), answer: Value('A'),
      ));
      await database.into(database.subQuestions).insert(db.SubQuestionsCompanion(
        questionId: Value(qId), sortOrder: Value(1), answer: Value('B'),
      ));
      final subs = await dao.getSubQuestions(qId);
      expect(subs.length, 2);
      expect(subs[0].sortOrder, 1);
      expect(subs[1].sortOrder, 2);
    });

    test('getChoiceExt returns correct options', () async {
      final qId = await insertQuestion();
      await database.into(database.choiceExt).insert(db.ChoiceExtCompanion(
        questionId: Value(qId), options: Value('{"A":"x>1"}'),
      ));
      final ext = await dao.getChoiceExt(qId);
      expect(ext, isNotNull);
      expect(ext!.options, contains('x>1'));
    });

    test('getMeta returns null when empty', () async {
      expect(await dao.getMeta(), isNull);
    });

    test('getAllConceptTags returns all tags', () async {
      await database.into(database.conceptTags).insert(db.ConceptTagsCompanion(name: Value('函数')));
      await database.into(database.conceptTags).insert(db.ConceptTagsCompanion(name: Value('三角')));
      expect((await dao.getAllConceptTags()).length, 2);
    });
  });
}
