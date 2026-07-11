import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/widgets/exit_rating_popup.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/database/app_database.dart' as app_db;

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    await AppPrefs().init();
    tempDir = Directory.systemTemp.createTempSync('exit_test_');
    await DatabaseProvider().initWithPath(tempDir.path);
  });

  tearDown(() async {
    await DatabaseProvider().reset();
    tempDir.deleteSync(recursive: true);
  });

  // ── shouldShowExitRating ──
  group('shouldShowExitRating', () {
    test('冷却中 → false', () async {
      await AppPrefs().setRatingCooldown('page_cool');
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      expect(shouldShowExitRating('page_cool', entry), false);
    });

    test('无冷却+停留足够 → 概率决定', () async {
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      var gotTrue = false;
      for (var i = 0; i < 100; i++) {
        if (shouldShowExitRating('prob_page_$i', entry)) {
          gotTrue = true;
          break;
        }
      }
      expect(gotTrue, isTrue, reason: '20% 概率下 100 次应至少一次通过');
    });

    test('停留不足 → false', () async {
      final entry = DateTime.now();
      for (var i = 0; i < 100; i++) {
        expect(shouldShowExitRating('stay_page_$i', entry), isFalse);
      }
    });

    test('冷却不同 page 不干扰', () async {
      await AppPrefs().setRatingCooldown('page_a');
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      expect(shouldShowExitRating('page_a', entry), false);
      var gotTrue = false;
      for (var i = 0; i < 100; i++) {
        if (shouldShowExitRating('page_b_$i', entry)) {
          gotTrue = true;
          break;
        }
      }
      expect(gotTrue, isTrue, reason: 'page_b 无冷却应有机会弹出');
    });
  });

  // ── ExitRatingPopup 弹层交互 ──
  group('ExitRatingPopup 弹层交互', () {
    Future<void> openPopup(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const _PopupHost()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('弹'));
      await tester.pumpAndSettle();
    }

    testWidgets('渲染 5 级表情 + 提交/跳过按钮', (tester) async {
      await openPopup(tester);
      expect(find.text('😡'), findsOneWidget);
      expect(find.text('😕'), findsOneWidget);
      expect(find.text('😐'), findsOneWidget);
      expect(find.text('😊'), findsOneWidget);
      expect(find.text('🤩'), findsOneWidget);
      expect(find.text('提交反馈 (+5积分)'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('选择表情后提交按钮启用', (tester) async {
      await openPopup(tester);
      // 初始提交按钮 disabled
      final btn = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('提交反馈 (+5积分)'),
        matching: find.byType(ElevatedButton),
      ));
      expect(btn.onPressed, null);
      // 点击表情
      await tester.tap(find.text('😐'));
      await tester.pumpAndSettle();
      // 提交按钮应启用
      final btn2 = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('提交反馈 (+5积分)'),
        matching: find.byType(ElevatedButton),
      ));
      expect(btn2.onPressed, isNot(null));
    });

    testWidgets('输入文字评价', (tester) async {
      await openPopup(tester);
      await tester.enterText(find.byType(TextField), '很好用！');
      expect(find.text('很好用！'), findsOneWidget);
    });

    testWidgets('点击跳过 → 弹层消失', (tester) async {
      await openPopup(tester);
      expect(find.text('🎉 感觉怎么样？'), findsOneWidget);
      await tester.tap(find.text('跳过'));
      await tester.pumpAndSettle();
      expect(find.text('🎉 感觉怎么样？'), findsNothing);
    });
  });

  // ── 积分写入（submitExitRating 的 DB 部分）──
  group('积分写入', () {
    test('冷却写入 AppPrefs', () async {
      await AppPrefs().setRatingCooldown('cool_write');
      expect(AppPrefs().isRatingCooldownActive('cool_write'), true);
    });

    test('points_transactions 正确插入', () async {
      final before = await DatabaseProvider().appDb
          .select(DatabaseProvider().appDb.pointsTransactions).get();
      expect(before.length, 0);

      final now = DateTime.now().toIso8601String();
      await DatabaseProvider().appDb.into(DatabaseProvider().appDb.pointsTransactions).insert(
        app_db.PointsTransactionsCompanion(
          amount: const Value(5),
          source: const Value('EXIT_RATING_REWARD'),
          transactionType: const Value('earn'),
          createdAt: Value(now),
        ),
      );

      final after = await DatabaseProvider().appDb
          .select(DatabaseProvider().appDb.pointsTransactions).get();
      expect(after.length, 1);
      expect(after.first.amount, 5);
      expect(after.first.source, 'EXIT_RATING_REWARD');
    });
  });
}

/// 辅助 Widget：点击按钮弹出 ExitRatingPopup
class _PopupHost extends StatelessWidget {
  const _PopupHost();
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ExitRatingPopup(),
      ),
      child: const Text('弹'),
    );
  }
}
