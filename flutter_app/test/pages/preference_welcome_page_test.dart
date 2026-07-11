import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/preference_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/pages/preference_welcome_page.dart';

void main() {
  late udb.AppDatabase uDb;
  late adb.AssetsDatabase aDb;
  late PreferenceDao dao;
  late QuestionDao qDao;
  late PreferenceRepository repo;

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    dao = PreferenceDao(uDb);
    qDao = QuestionDao(aDb);
    repo = PreferenceRepository(dao);
  });

  tearDown(() {
    uDb.close();
    aDb.close();
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

  group('PreferenceWelcomePage', () {
    testWidgets('欢迎页展示 🎉 和积分提示', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('欢迎加入章鱼智学！'), findsOneWidget);
      expect(find.text('首次注册赠送 +10 积分'), findsOneWidget);
      expect(find.text('👌 开始设置学习偏好'), findsOneWidget);
    });

    testWidgets('点击开始设置 → 显示偏好表单', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👌 开始设置学习偏好'));
      await tester.pumpAndSettle();
      expect(find.text('设置学习偏好'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('💾 保存偏好'), findsOneWidget);
    });

    testWidgets('空名称保存失败提示', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👌 开始设置学习偏好'));
      await tester.pumpAndSettle();
      // 清空名称
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('💾 保存偏好'));
      await tester.pumpAndSettle();
      expect(find.text('请输入偏好名称'), findsOneWidget);
    });

    testWidgets('保存后偏好列表应有记录', (tester) async {
      await tester.pumpWidget(MaterialApp(home: PreferenceWelcomePage(preferenceRepository: repo, questionDao: qDao)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👌 开始设置学习偏好'));
      await tester.pumpAndSettle();
      // 保存偏好（默认名称已填）
      await tester.tap(find.text('💾 保存偏好'));
      await tester.pumpAndSettle();
      // 偏好已保存
      expect(await repo.getCount(), 1);
    });
  });
}
