import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/daos/exam_dao.dart';
import 'package:flutter_app/domain/exam_repository.dart';

void main() {
  late adb.AssetsDatabase aDb;
  late udb.AppDatabase uDb;
  late QuestionDao qDao;
  late ExamDao eDao;
  late ExamRepository repo;

  setUp(() {
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    uDb = udb.AppDatabase(NativeDatabase.memory());
    qDao = QuestionDao(aDb);
    eDao = ExamDao(uDb);
    repo = ExamRepository(qDao, eDao);
  });

  tearDown(() {
    aDb.close();
    uDb.close();
  });

  group('ExamRepository', () {
    test('getMyExams returns empty initially', () async {
      expect(await repo.getMyExams(), isEmpty);
    });

    test('getExploreList returns empty initially', () async {
      expect(await repo.getExploreList(), isEmpty);
    });

    test('getFilterOptions returns values from assets', () async {
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(1), year: const Value(2024),
        examType: const Value('一模'), region: const Value('海淀'),
        number: const Value('1'), questionType: const Value('choice'),
        stem: const Value('题'),
      ));
      await aDb.into(aDb.conceptTags).insert(adb.ConceptTagsCompanion(
        id: const Value(1), name: const Value('函数'),
      ));
      final opts = await repo.getFilterOptions();
      expect(opts.years, contains('2024'));
      expect(opts.regions, contains('海淀'));
    });

    test('confirm creates paper and returns id', () async {
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(1), year: const Value(2024),
        examType: const Value('一模'), region: const Value('海淀'),
        number: const Value('1'), questionType: const Value('choice'),
        stem: const Value('题'),
      ));
      final id = await repo.confirm(const SearchFilters(
        name: '测试', choiceCount: 1, fillCount: 0, solutionCount: 0,
        targetDifficulty: 5, years: [], regions: [], conceptTags: [], knowledgeCards: [],
      ));
      expect(id, greaterThan(0));
      expect((await repo.getMyExams()).length, 1);
    });

    test('confirm throws when pool insufficient', () async {
      expect(() => repo.confirm(const SearchFilters(
        name: '不足', choiceCount: 5, fillCount: 0, solutionCount: 0,
        targetDifficulty: 5, years: [], regions: [], conceptTags: [], knowledgeCards: [],
      )), throwsA(isA<InsufficientPoolException>()));
    });

    test('getPreview returns paper info', () async {
      // 创建试卷
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(1), year: const Value(2024),
        examType: const Value('一模'), region: const Value('海淀'),
        number: const Value('1'), questionType: const Value('choice'),
        stem: const Value('题'),
      ));
      final paperId = await eDao.savePaper(title: '我的试卷');
      await eDao.savePaperQuestions(paperId, [1]);
      final preview = await repo.getPreview(paperId);
      expect(preview.name, '我的试卷');
      expect(preview.totalCount, 1);
    });

    test('deleteExam removes paper', () async {
      final id = await eDao.savePaper(title: '待删');
      await repo.deleteExam(id);
      expect(await repo.getMyExams(), isEmpty);
    });

    test('toggleLike adds then removes', () async {
      final id = await eDao.savePaper(title: 't');
      await repo.toggleLike(id);
      await repo.toggleLike(id); // toggle back
    });

    test('getFilteredQuestions returns matching questions', () async {
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(1), year: const Value(2024),
        examType: const Value('一模'), region: const Value('海淀'),
        number: const Value('1'), questionType: const Value('choice'),
        stem: const Value('题 A'), difficulty: const Value(3.0),
      ));
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(2), year: const Value(2024),
        examType: const Value('一模'), region: const Value('东城'),
        number: const Value('2'), questionType: const Value('choice'),
        stem: const Value('题 B'), difficulty: const Value(7.0),
      ));
      final qs = await repo.getFilteredQuestions(const SearchFilters(
        name: '', choiceCount: 0, fillCount: 0, solutionCount: 0,
        targetDifficulty: 5, regions: ['海淀'], conceptTags: [], knowledgeCards: [],
        years: ['2024'], diffMin: 0, diffMax: 5,
      ));
      expect(qs.length, 1);
      expect(qs.first.id, 1);
    });
  });
}
