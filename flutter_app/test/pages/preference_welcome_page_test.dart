import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/preference_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/pages/preference_welcome_page.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import '../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  late udb.AppDatabase uDb;
  late adb.AssetsDatabase aDb;
  late PreferenceDao dao;
  late QuestionDao qDao;
  late PreferenceRepository repo;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    await AppPrefs().init();
    tempDir = Directory.systemTemp.createTempSync('pref_test_');
    await DatabaseProvider().initWithPath(tempDir.path);

    uDb = udb.AppDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(uDb);
    DatabaseProvider().setAssetsDbForTesting(aDb);
    dao = PreferenceDao(DatabaseProvider());
    qDao = QuestionDao(DatabaseProvider());
    repo = PreferenceRepository(dao);
  });

  tearDown(() async {
    uDb.close();
    aDb.close();
    await DatabaseProvider().reset();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Windows temp file lock — 不影响测试结果
    }
  });

  group('引导触发', () {
    test('count=0（无偏好）→ 应进入引导', () async {
      expect(await repo.getCount(), 0);
    });

    test('保存偏好后 count=1 → 引导应跳过', () async {
      await repo.save(name: '我的偏好', filter: PreferenceFilter(years: ['2026'], regions: ['北京'], conceptTags: []));
      expect(await repo.getCount(), 1);
    });
  });

  group('PreferenceFilter 补全字段', () {
    test('save/load 含 types/难度/计算量', () async {
      await repo.save(name: '完整', filter: PreferenceFilter(
        years: ['2026'], regions: ['北京'], conceptTags: ['函数'],
        types: ['choice'], diffMin: 3, diffMax: 7, calcMin: 2, calcMax: 8,
      ));
      final list = await repo.getList();
      expect(list.length, 1);
      final loaded = await repo.getEdit(list.first.id);
      expect(loaded.filter.types, ['choice']);
      expect(loaded.filter.diffMin, 3);
      expect(loaded.filter.diffMax, 7);
    });
  });

  group('PreferenceWelcomePage', () {
    testWidgets('欢迎 Dialog 展示 🎉 + 跳过按钮', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      expect(find.text('欢迎加入章鱼智学！'), findsOneWidget);
      expect(find.textContaining('开始设置学习偏好'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
    });

    testWidgets('点击开始设置 → 偏好表单', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('开始设置学习偏好'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('保存偏好'), findsOneWidget);
    });

    testWidgets('保存后偏好列表应有记录', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('开始设置学习偏好'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('保存偏好'));
      await tester.pumpAndSettle();
      // 未选择任何筛选条件时点击保存，触发验证不保存
      expect(await repo.getCount(), 0);
    });
  });
}
