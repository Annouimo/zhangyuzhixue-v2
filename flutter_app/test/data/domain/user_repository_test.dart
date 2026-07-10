import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:dio/dio.dart';
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/daos/user_dao.dart';
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

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    dao = UserDao(uDb);
    client = ApiClient();
    client.init(baseUrl: 'https://test/');
    adapter = _MockAdapter();
    client.setMockAdapter(adapter);
  });

  tearDown(() => uDb.close());

  group('UserRepository', () {
    test('getUserInfo returns cached profile when exists', () async {
      await dao.saveProfile(id: 1, name: 'cached', realName: '小明');
      final repo = UserRepository(dao, UserApi(client));
      final info = await repo.getUserInfo();
      expect(info.name, 'cached');
    });

    test('getUserInfo falls back to API', () async {
      adapter.on('GET', '/user/me/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"id":1,"username":"api_user","real_name":"小红"}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      final repo = UserRepository(dao, UserApi(client));
      final info = await repo.getUserInfo();
      expect(info.name, 'api_user');
      expect(info.realName, '小红');
    });

    test('saveProfile then getUserInfo works', () async {
      await dao.saveProfile(id: 1, name: 'test', realName: '小明');
      final repo = UserRepository(dao, UserApi(client));
      final info = await repo.getUserInfo();
      expect(info.name, 'test');
      expect(info.realName, '小明');
    });

    test('earnedPoints returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client));
      expect(await repo.earnedPoints(), 0);
    });

    test('streakDays returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client));
      expect(await repo.streakDays(), 0);
    });

    test('getPointsHistory returns empty', () async {
      final repo = UserRepository(dao, UserApi(client));
      expect(await repo.getPointsHistory(), isEmpty);
    });
  });

  group('_PointsCalculator', () {
    test('earnedPoints returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client));
      expect(await repo.earnedPoints(), 0);
    });

    test('spentPoints returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client));
      expect(await repo.spentPoints(), 0);
    });

    test('bonusPoints returns 0 initially', () async {
      final repo = UserRepository(dao, UserApi(client));
      expect(await repo.bonusPoints(), 0);
    });
  });
}
