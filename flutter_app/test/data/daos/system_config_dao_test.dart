import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/system_config_dao.dart';

adb.AssetsDatabase _makeEmptyDb() {
  return adb.AssetsDatabase(NativeDatabase.memory());
}

adb.AssetsDatabase _makePrefilledDb() {
  final db = adb.AssetsDatabase(NativeDatabase.memory());
  db.into(db.systemConfigs).insert(adb.SystemConfigsCompanion.insert(
    key: 'exit_rating_probability',
    value: '0.3',
  ));
  db.into(db.systemConfigs).insert(adb.SystemConfigsCompanion.insert(
    key: 'exit_rating_reward_points',
    value: '10',
  ));
  return db;
}

void main() {
  group('SystemConfigDao', () {
    test('get returns fallback when key missing', () async {
      final db = _makeEmptyDb();
      final dao = SystemConfigDao(db);
      expect(await dao.get('nonexistent', 'default'), 'default');
      await db.close();
    });

    test('getInt returns fallback when key missing', () async {
      final db = _makeEmptyDb();
      final dao = SystemConfigDao(db);
      expect(await dao.getInt('missing', 42), 42);
      await db.close();
    });

    test('getDouble returns fallback when key missing', () async {
      final db = _makeEmptyDb();
      final dao = SystemConfigDao(db);
      expect(await dao.getDouble('missing', 3.14), closeTo(3.14, 0.001));
      await db.close();
    });

    test('get returns stored value', () async {
      final db = _makePrefilledDb();
      final dao = SystemConfigDao(db);
      expect(await dao.get('exit_rating_probability', '0.2'), '0.3');
      await db.close();
    });

    test('getInt parses stored value', () async {
      final db = _makePrefilledDb();
      final dao = SystemConfigDao(db);
      expect(await dao.getInt('exit_rating_reward_points', 5), 10);
      await db.close();
    });

    test('cache returns cached value without second query', () async {
      final db = _makePrefilledDb();
      final dao = SystemConfigDao(db);
      // First call populates cache
      expect(await dao.get('exit_rating_probability', ''), '0.3');
      // Delete from DB — cache should still return old value
      await (db.delete(db.systemConfigs)
            ..where((t) => t.key.equals('exit_rating_probability')))
          .go();
      expect(await dao.get('exit_rating_probability', ''), '0.3');
      await db.close();
    });

    test('clearCache forces re-read', () async {
      final db = _makePrefilledDb();
      final dao = SystemConfigDao(db);
      expect(await dao.get('exit_rating_probability', ''), '0.3');
      dao.clearCache();
      await (db.delete(db.systemConfigs)
            ..where((t) => t.key.equals('exit_rating_probability')))
          .go();
      expect(await dao.get('exit_rating_probability', 'fallback'), 'fallback');
      await db.close();
    });
  });
}
