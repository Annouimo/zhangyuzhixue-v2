import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/domain/review_repository.dart';

void main() {
  late adb.AssetsDatabase assets;
  late udb.AppDatabase user;
  late ProgressDao progressDao;
  late ReviewRepository repository;

  setUp(() {
    assets = adb.AssetsDatabase(NativeDatabase.memory());
    user = udb.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAssetsDbForTesting(assets);
    DatabaseProvider().setAppDbForTesting(user);
    progressDao = ProgressDao(DatabaseProvider());
    repository = ReviewRepository(QuestionDao(DatabaseProvider()), progressDao);
  });

  tearDown(() async {
    await assets.close();
    await user.close();
  });

  test('derives needs-review status from existing attempts', () async {
    await assets
        .into(assets.conceptTags)
        .insert(
          adb.ConceptTagsCompanion(id: const Value(1), name: const Value('函数')),
        );
    for (var id = 1; id <= 2; id++) {
      await assets
          .into(assets.questions)
          .insert(
            adb.QuestionsCompanion(
              id: Value(id),
              year: const Value(2024),
              examType: const Value('一模'),
              region: const Value('海淀'),
              number: Value('$id'),
              questionType: const Value('choice'),
              stem: Value('题 $id'),
            ),
          );
      await assets
          .into(assets.questionConceptTags)
          .insert(
            adb.QuestionConceptTagsCompanion(
              questionId: Value(id),
              conceptTagId: const Value(1),
            ),
          );
      final attemptId = await progressDao.createAttempt(questionId: id);
      await progressDao.updateAttemptAnswer(attemptId, 'A', 0);
    }

    final result = await repository.getConceptProgress();
    expect(result.single.name, '函数');
    expect(result.single.status, ConceptProgressStatus.needsReview);
  });
}
