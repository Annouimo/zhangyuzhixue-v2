import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/lectures_database.dart' as ldb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/assignment_dao.dart';
import 'package:flutter_app/domain/assignment_repository.dart';

void main() {
  late ldb.LecturesDatabase lDb;
  late adb.AssetsDatabase aDb;
  late AssignmentDao dao;
  late AssignmentRepository repo;

  setUp(() {
    lDb = ldb.LecturesDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    dao = AssignmentDao(lDb);
    repo = AssignmentRepository(dao);
  });

  tearDown(() {
    lDb.close();
    aDb.close();
  });

  group('AssignmentRepository', () {
    test('pendingCount returns 0 initially', () async {
      expect(await repo.pendingCount(), 0);
    });

    test('getPending returns empty initially', () async {
      final list = await repo.getPending();
      expect(list, isEmpty);
    });

    test('getQuestions throws for nonexistent', () async {
      expect(() => repo.getQuestions(999), throwsA(isA<Exception>()));
    });
  });
}
