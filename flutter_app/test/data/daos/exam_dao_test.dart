import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/exam_dao.dart';

void main() {
  late db.AppDatabase database;
  late ExamDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = ExamDao(database);
  });

  tearDown(() => database.close());

  group('ExamDao', () {
    test('listCreated returns empty initially', () async {
      expect(await dao.listCreated(), isEmpty);
    });

    test('savePaper and listCreated', () async {
      await dao.savePaper(title: '我的组卷');
      final list = await dao.listCreated();
      expect(list.length, 1);
      expect(list.first.title, '我的组卷');
    });

    test('getById returns saved paper', () async {
      final id = await dao.savePaper(title: 'T');
      final paper = await dao.getById(id);
      expect(paper, isNotNull);
      expect(paper!.title, 'T');
    });

    test('deletePaper removes paper', () async {
      final id = await dao.savePaper(title: 'T');
      await dao.deletePaper(id);
      expect(await dao.getById(id), isNull);
    });

    test('savePaperQuestions replaces questions', () async {
      final id = await dao.savePaper(title: 'T');
      await dao.savePaperQuestions(id, [1, 2, 3]);
      var questions = await dao.getQuestions(id);
      expect(questions.length, 3);
      expect(questions[0].questionId, 1);
      expect(questions[1].questionId, 2);

      await dao.savePaperQuestions(id, [10, 20]);
      questions = await dao.getQuestions(id);
      expect(questions.length, 2);
    });

    test('toggleLike adds and removes', () async {
      await dao.toggleLike(1);
      expect(await dao.getLike(1), isNotNull);
      await dao.toggleLike(1);
      expect(await dao.getLike(1), isNull);
    });

    test('toggleCollect adds and removes', () async {
      await dao.toggleCollect(1);
      expect(await dao.getCollect(1), isNotNull);
      await dao.toggleCollect(1);
      expect(await dao.getCollect(1), isNull);
    });

    test('togglePublic flips is_public', () async {
      final id = await dao.savePaper(title: 'T');
      await dao.togglePublic(id);
      var paper = await dao.getById(id);
      expect(paper!.isPublic, 1);
      await dao.togglePublic(id);
      paper = await dao.getById(id);
      expect(paper!.isPublic, 0);
    });

    test('getPaperCount returns 0 initially', () async {
      expect(await dao.getPaperCount(), 0);
    });

    test('getPaperCount returns count after saving', () async {
      await dao.savePaper(title: '组卷A');
      expect(await dao.getPaperCount(), 1);
      await dao.savePaper(title: '组卷B');
      expect(await dao.getPaperCount(), 2);
    });
  });
}
