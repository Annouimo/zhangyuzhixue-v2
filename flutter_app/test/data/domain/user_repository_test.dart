import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:dio/dio.dart';
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/user_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/user_api.dart';
import 'package:flutter_app/domain/user_repository.dart';

class _MockAdapter implements HttpClientAdapter {
  final handlers = <String, Function(RequestOptions)>{};
  void on(String method, String path, Function(RequestOptions) h) {
    handlers['$method $path'] = h;
  }
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? rs, Future? cf) async {
    final h = handlers['${o.method} ${o.path}'];
    if (h != null) return h(o);
    return ResponseBody.fromString('{"code":0,"data":{}}', 200, headers: {'content-type': ['application/json']});
  }
  @override void close({bool? force}) {}
}

void main() {
  late udb.AppDatabase uDb;
  late UserDao dao;
  late ApiClient client;
  late _MockAdapter adapter;
  late adb.AssetsDatabase aDb;
  late QuestionDao qDao;

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    dao = UserDao(uDb);
    qDao = QuestionDao(aDb);
    client = ApiClient();
    client.init(baseUrl: 'https://test/');
    adapter = _MockAdapter();
    client.setMockAdapter(adapter);
  });

  tearDown(() {
    uDb.close();
    aDb.close();
  });

  group('UserRepository', () {
    test('getUserInfo returns cached profile when exists', () async {
      await dao.saveProfile(id: 1, name: 'cached', realName: '小明');
      final repo = UserRepository(dao, UserApi(client), qDao);
      final info = await repo.getUserInfo();
      expect(info.name, 'cached');
    });

    test('getUserInfo falls back to API', () async {
      adapter.on('GET', '/user/me/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"id":1,"username":"api_user","real_name":"小红"}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      final repo = UserRepository(dao, UserApi(client), qDao);
      final info = await repo.getUserInfo();
      expect(info.name, 'api_user');
      expect(info.realName, '小红');
    });

    test('saveProfile then getUserInfo works', () async {
      await dao.saveProfile(id: 1, name: 'test', realName: '小明');
      final repo = UserRepository(dao, UserApi(client), qDao);
      final info = await repo.getUserInfo();
      expect(info.name, 'test');
      expect(info.realName, '小明');
    });

    test('earnedPoints returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client), qDao);
      expect(await repo.earnedPoints(), 0);
    });

    test('streakDays returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client), qDao);
      expect(await repo.streakDays(), 0);
    });

    test('getPointsHistory returns empty', () async {
      final repo = UserRepository(dao, UserApi(client), qDao);
      expect(await repo.getPointsHistory(), isEmpty);
    });
  });

  group('积分引擎 (_PointsCalculator)', () {
    UserRepository makeRepo() => UserRepository(dao, UserApi(client), qDao);

    /// 助手：直接向 points_transactions 表插入一条记录
    Future<void> insertTx({
      required double amount,
      required String source,
      String transactionType = 'earn',
      String createdAt = '2026-07-11T10:00:00',
    }) async {
      await uDb.into(uDb.pointsTransactions).insert(udb.PointsTransactionsCompanion(
        amount: Value(amount),
        source: Value(source),
        transactionType: Value(transactionType),
        createdAt: Value(createdAt),
      ));
    }

    // ── earned ──
    test('earned=0 无数据', () async {
      final repo = makeRepo();
      expect(await repo.earnedPoints(), 0);
    });

    test('earned=0 LOGIN_BONUS 不再计入（现为 bonus）', () async {
      await insertTx(amount: 30, source: 'LOGIN_BONUS');
      await insertTx(amount: 20, source: 'LOGIN_BONUS');
      final repo = makeRepo();
      expect(await repo.earnedPoints(), 0);
    });

    test('earned=3.0 仅 PRACTICE_REWARD', () async {
      await insertTx(amount: 1.0, source: 'LOGIN_BONUS');
      await insertTx(amount: 3.0, source: 'PRACTICE_REWARD');
      await insertTx(amount: 2.0, source: 'TASK_REWARD');
      final repo = makeRepo();
      expect(await repo.earnedPoints(), 3.0);
    });

    test('earned 排除非 earned 来源（LOGIN_BONUS+SIGNUP_BONUS 不计入）', () async {
      await insertTx(amount: 10.0, source: 'SIGNUP_BONUS');
      await insertTx(amount: 1.5, source: 'LOGIN_BONUS');
      final repo = makeRepo();
      expect(await repo.earnedPoints(), 0.0);
    });

    // ── bonus ──
    test('bonus=5.0 LOGIN_BONUS 计入 bonus', () async {
      await insertTx(amount: 5.0, source: 'LOGIN_BONUS');
      final repo = makeRepo();
      expect(await repo.bonusPoints(), 5.0);
    });

    test('bonus=25.0 SIGNUP_BONUS+LOGIN_BONUS 合计', () async {
      await insertTx(amount: 20.0, source: 'SIGNUP_BONUS');
      await insertTx(amount: 5.0, source: 'LOGIN_BONUS');
      final repo = makeRepo();
      expect(await repo.bonusPoints(), 25.0);
    });

    // ── spent ──
    test('spent=0 无 PAPER_PURCHASE', () async {
      await insertTx(amount: 5.0, source: 'LOGIN_BONUS');
      final repo = makeRepo();
      expect(await repo.spentPoints(), 0.0);
    });

    test('spent=3.0 含 PAPER_PURCHASE', () async {
      await insertTx(amount: -1.0, source: 'PAPER_PURCHASE');
      await insertTx(amount: -2.0, source: 'PAPER_PURCHASE');
      final repo = makeRepo();
      expect(await repo.spentPoints(), 3.0); // abs 求和
    });

    // ── available（公式：earned + bonus - spent）──
    test('available=earned+bonus-spent 公式正确', () async {
      await insertTx(amount: 10.0, source: 'PRACTICE_REWARD');  // earned
      await insertTx(amount: 20.0, source: 'SIGNUP_BONUS');     // bonus
      await insertTx(amount: -3.0, source: 'PAPER_PURCHASE');   // spent
      final repo = makeRepo();
      // available = 10 + 20 - 3 = 27
      expect(await repo.availablePoints(), 27.0);
    });

    test('available 负数场景', () async {
      await insertTx(amount: 1.0, source: 'PRACTICE_REWARD');   // earned
      await insertTx(amount: 0.0, source: 'SIGNUP_BONUS');       // bonus=0
      await insertTx(amount: -5.0, source: 'PAPER_PURCHASE');   // spent=5
      final repo = makeRepo();
      expect(await repo.availablePoints(), -4.0);
    });

    // ── getPointsHistory 含汇总 ──
    test('getPointsHistory 每条 PointsRecord 含实时汇总值', () async {
      await insertTx(amount: 10.0, source: 'LOGIN_BONUS', createdAt: '2026-07-10T10:00:00');
      await insertTx(amount: 5.0, source: 'SIGNUP_BONUS', createdAt: '2026-07-11T10:00:00');
      final repo = makeRepo();
      final history = await repo.getPointsHistory();
      expect(history.length, 2);
      // 最新一条排前面（SIGNUP_BONUS）
      expect(history[0].type, '新人赠送');
      expect(history[0].change, 5.0);
      expect(history[0].earned, 0.0);      // 无 PRACTICE_REWARD
      expect(history[0].bonus, 15.0);     // 10+5
      expect(history[0].spent, 0.0);
      expect(history[0].available, 15.0);
      // 第二条（LOGIN_BONUS）
      expect(history[1].type, '签到');
      expect(history[1].change, 10.0);
      expect(history[1].earned, 0.0);
      expect(history[1].bonus, 10.0);
      expect(history[1].spent, 0.0);
      expect(history[1].available, 10.0);
    });
  });
}
