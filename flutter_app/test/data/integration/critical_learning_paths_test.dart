@Tags(['integration'])
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/daos/exam_dao.dart';
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/database/app_database.dart' as app_db;
import 'package:flutter_app/data/database/assets_database.dart' as assets_db;
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/sync/sync_manager.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/domain/progress_repository.dart';
import 'package:flutter_app/domain/question_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessfulSyncAdapter implements HttpClientAdapter {
  final List<List<Map<String, dynamic>>> batches = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final body = options.data! as Map<String, dynamic>;
    final batch = (body['batch']! as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    batches.add(batch);
    final serverIds = <String, int>{
      for (final item in batch)
        '${item['client_ref']}': (item['local_id'] as int) + 1000,
    };
    return ResponseBody.fromString(
      jsonEncode({
        'code': 0,
        'data': {'server_ids': serverIds},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool? force}) {}
}

void main() {
  late app_db.AppDatabase appDb;
  late assets_db.AssetsDatabase assetsDb;
  late QuestionDao questionDao;
  late ProgressDao progressDao;
  late ExamDao examDao;
  late SyncQueueDao queueDao;
  late _SuccessfulSyncAdapter syncAdapter;

  setUp(() async {
    appDb = app_db.AppDatabase(NativeDatabase.memory());
    assetsDb = assets_db.AssetsDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(appDb);
    DatabaseProvider().setAssetsDbForTesting(assetsDb);
    questionDao = QuestionDao(DatabaseProvider());
    progressDao = ProgressDao(DatabaseProvider());
    examDao = ExamDao(DatabaseProvider());
    queueDao = SyncQueueDao(DatabaseProvider());

    final client = ApiClient()..init(baseUrl: 'https://integration.test');
    syncAdapter = _SuccessfulSyncAdapter();
    client.setMockAdapter(syncAdapter);
    await SyncManager().init(queueDao, SyncApi(client), DatabaseProvider());
  });

  tearDown(() async {
    await SyncManager.resetForTesting();
    await DatabaseProvider().reset();
  });

  test(
    'choice answer persists completion, reward, and sync payloads',
    () async {
      await _insertQuestion(assetsDb, id: 1, type: 'choice', difficulty: 7.4);
      final repository = QuestionRepository(questionDao, progressDao);

      await repository.startSolve(1);
      await repository.saveAttempt(1, answerText: 'A', isCorrect: true);

      final attempt = await progressDao.getLatestAttempt(1);
      expect(attempt?.status, 'completed');
      expect(attempt?.answerText, 'A');
      expect(attempt?.isCorrect, 1);

      final rewards = await appDb.select(appDb.pointsTransactions).get();
      expect(rewards, hasLength(1));
      expect(rewards.single.amount, 0.7);

      final queue = await appDb.select(appDb.syncQueue).get();
      expect(queue.map((item) => item.entityType), [
        'submission',
        'points_transaction',
      ]);
      expect(queue.map((item) => item.status), everyElement('done'));
      final submissionPayload =
          jsonDecode(queue.first.payload) as Map<String, dynamic>;
      expect(submissionPayload['details'][0], containsPair('answer_text', 'A'));
    },
  );

  test(
    'solution steps complete attempt and sync all derived records',
    () async {
      await _insertQuestion(assetsDb, id: 2, type: 'solution', difficulty: 6.8);
      await assetsDb
          .into(assetsDb.subQuestions)
          .insert(
            const assets_db.SubQuestionsCompanion(
              id: Value(20),
              questionId: Value(2),
              sortOrder: Value(1),
            ),
          );
      await assetsDb
          .into(assetsDb.solutionMethods)
          .insert(
            const assets_db.SolutionMethodsCompanion(
              id: Value(30),
              subQuestionId: Value(20),
              methodName: Value('标准解法'),
              sortOrder: Value(1),
            ),
          );
      for (var step = 1; step <= 2; step++) {
        await assetsDb
            .into(assetsDb.solutionSteps)
            .insert(
              assets_db.SolutionStepsCompanion(
                id: Value(30 + step),
                methodId: const Value(30),
                stepNumber: Value(step),
                title: Value('步骤 $step'),
                content: Value('过程 $step'),
              ),
            );
      }
      final repository = ProgressRepository(progressDao, questionDao);
      await repository.createAttempt(2);

      await repository.submitStepFeedback(
        questionId: 2,
        attemptNumber: 1,
        subQuestionIndex: 0,
        methodIndex: 0,
        stepNumber: 1,
        status: 'correct',
      );
      expect((await progressDao.getLatestAttempt(2))?.status, 'in_progress');

      await repository.submitStepFeedback(
        questionId: 2,
        attemptNumber: 1,
        subQuestionIndex: 0,
        methodIndex: 0,
        stepNumber: 2,
        status: 'correct',
      );

      expect((await progressDao.getLatestAttempt(2))?.status, 'completed');
      expect(await progressDao.getStepFeedbacks(1), hasLength(2));
      expect(await appDb.select(appDb.pointsTransactions).get(), hasLength(1));
      final queue = await appDb.select(appDb.syncQueue).get();
      expect(queue.map((item) => item.entityType), [
        'step_feedback',
        'step_feedback',
        'submission',
        'points_transaction',
      ]);
      expect(queue.map((item) => item.status), everyElement('done'));
    },
  );

  test(
    'generated paper persists selected questions and syncs exact ids',
    () async {
      await _insertQuestion(assetsDb, id: 11, type: 'choice', difficulty: 4);
      await _insertQuestion(assetsDb, id: 12, type: 'choice', difficulty: 6);
      final repository = ExamRepository(questionDao, examDao);

      final paperId = await repository.confirm(
        const SearchFilters(
          name: '函数基础卷',
          choiceCount: 2,
          fillCount: 0,
          solutionCount: 0,
          targetDifficulty: 5,
          years: [],
          regions: [],
          conceptTags: [],
          knowledgeCards: [],
        ),
      );

      final paperQuestions = await examDao.getQuestions(paperId);
      expect(paperQuestions.map((item) => item.questionId), [11, 12]);
      final queue = await appDb.select(appDb.syncQueue).get();
      expect(queue, hasLength(1));
      expect(queue.single.entityType, 'custom_paper');
      expect(queue.single.status, 'done');
      final payload = jsonDecode(queue.single.payload) as Map<String, dynamic>;
      expect(payload['title'], '函数基础卷');
      expect(payload['questions'], [11, 12]);
    },
  );
}

Future<void> _insertQuestion(
  assets_db.AssetsDatabase database, {
  required int id,
  required String type,
  required double difficulty,
}) {
  return database
      .into(database.questions)
      .insert(
        assets_db.QuestionsCompanion(
          id: Value(id),
          year: const Value(2026),
          examType: const Value('模拟'),
          region: const Value('北京'),
          number: Value('$id'),
          questionType: Value(type),
          difficulty: Value(difficulty),
          stem: Value('题目 $id'),
        ),
      );
}
