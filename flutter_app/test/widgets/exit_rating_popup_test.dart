import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/widgets/exit_rating_popup.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/data/daos/system_config_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/assets_database.dart' as adb;

/// 创建一个带默认 system_config 行数据的 mock AssetsDatabase
adb.AssetsDatabase _makeAssetsDb() {
  final db = adb.AssetsDatabase(NativeDatabase.memory());
  // 写入默认配置
  db.into(db.systemConfigs).insert(adb.SystemConfigsCompanion.insert(
    key: 'exit_rating_probability',
    value: '0.2',
  ));
  db.into(db.systemConfigs).insert(adb.SystemConfigsCompanion.insert(
    key: 'exit_rating_min_stay_seconds',
    value: '30',
  ));
  db.into(db.systemConfigs).insert(adb.SystemConfigsCompanion.insert(
    key: 'exit_rating_reward_points',
    value: '5',
  ));
  return db;
}

void main() {
  late adb.AssetsDatabase aDb;
  late ExitRatingConfig config;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    await AppPrefs().init();
    aDb = _makeAssetsDb();
    config = ExitRatingConfig(SystemConfigDao(aDb));
  });

  tearDown(() => aDb.close());

  group('shouldShowExitRating', () {
    test('冷却中 → false', () async {
      await AppPrefs().setRatingCooldown('page_cool');
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      expect(await shouldShowExitRating('page_cool', entry, config), false);
    });

    test('无冷却 + 停留足够 → 概率决定', () async {
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      var gotTrue = false;
      for (var i = 0; i < 100; i++) {
        if (await shouldShowExitRating('prob_page_$i', entry, config)) {
          gotTrue = true;
          break;
        }
      }
      expect(gotTrue, isTrue, reason: '20% 概率下 100 次应至少一次通过');
    });

    test('停留不足 → false', () async {
      final entry = DateTime.now();
      for (var i = 0; i < 30; i++) {
        expect(
            await shouldShowExitRating('stay_page_$i', entry, config), isFalse);
      }
    });

    test('冷却不同 page 不干扰', () async {
      await AppPrefs().setRatingCooldown('page_a');
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      expect(await shouldShowExitRating('page_a', entry, config), false);
      var gotTrue = false;
      for (var i = 0; i < 100; i++) {
        if (await shouldShowExitRating('page_b_$i', entry, config)) {
          gotTrue = true;
          break;
        }
      }
      expect(gotTrue, isTrue, reason: 'page_b 无冷却应有机会弹出');
    });
  });

  group('submitExitRating（冷却部分）', () {
    test('冷却写入生效', () async {
      await AppPrefs().setRatingCooldown('direct_page');
      expect(AppPrefs().isRatingCooldownActive('direct_page'), true);
    });

    test('配置从 DB 读取', () async {
      expect(await config.probability, closeTo(0.2, 0.001));
      expect(await config.minStaySeconds, 30);
      expect(await config.rewardPoints, 5);
    });
  });

  group('ExitRatingPopup', () {
    testWidgets('渲染 5 级表情 + 提交/跳过按钮', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) =>
                    ExitRatingPopup(rewardPoints: Future.value(5)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      expect(find.text('🎉 感觉怎么样？'), findsOneWidget);
      expect(find.text('提交反馈 (+5积分)'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
    });
  });
}
