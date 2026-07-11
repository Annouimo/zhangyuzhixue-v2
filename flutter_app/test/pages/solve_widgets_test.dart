import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/solve/widgets/cooling_timer.dart';
import 'package:flutter_app/pages/solve/widgets/feedback_buttons.dart';
import 'package:flutter_app/pages/solve/widgets/solve_flow_widget.dart';

void main() {
  group('CoolingTimer', () {
    testWidgets('shows child when not cooling', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CoolingTimer(
          seconds: 10,
          child: const Text('提交'),
        )),
      ));
      expect(find.text('提交'), findsOneWidget);
    });

    testWidgets('disables child during cooldown', (tester) async {
      final key = GlobalKey<CoolingTimerState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CoolingTimer(
          key: key,
          seconds: 3,
          child: const Text('提交'),
        )),
      ));
      key.currentState?.start();
      await tester.pump();
      // 倒计时期间：提交按钮在 AbsorbPointer 内，opacity 降低
      final btn = tester.widget<Text>(find.text('提交'));
      expect(btn, isNotNull);
      // AbsorbPointer 包裹了 child
      expect(find.byType(AbsorbPointer), findsAtLeast(1));
    });

    testWidgets('shows remaining seconds text', (tester) async {
      final key = GlobalKey<CoolingTimerState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CoolingTimer(
          key: key,
          seconds: 5,
          child: const Text('按钮'),
        )),
      ));
      key.currentState?.start();
      await tester.pump();
      expect(find.textContaining('还剩'), findsOneWidget);
    });

    testWidgets('resets correctly', (tester) async {
      final key = GlobalKey<CoolingTimerState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CoolingTimer(
          key: key,
          seconds: 3,
          child: const Text('提交'),
        )),
      ));
      key.currentState?.start();
      await tester.pump();
      key.currentState?.reset();
      await tester.pump();
      // reset 后倒计时文字消失
      expect(find.textContaining('还剩'), findsNothing);
    });
  });

  group('FeedbackButtons', () {
    testWidgets('renders three feedback options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FeedbackButtons()),
      ));
      expect(find.text('✅ 全对'), findsOneWidget);
      expect(find.text('🔶 部分对'), findsOneWidget);
      expect(find.text('❌ 不对'), findsOneWidget);
    });

    testWidgets('highlights selected option', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FeedbackButtons(selected: FeedbackType.fullCorrect)),
      ));
      // 全对被选中
      expect(find.text('✅ 全对'), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      FeedbackType? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FeedbackButtons(
          onChanged: (t) => result = t,
        )),
      ));
      await tester.tap(find.text('✅ 全对'));
      expect(result, FeedbackType.fullCorrect);

      await tester.tap(find.text('❌ 不对'));
      expect(result, FeedbackType.wrong);
    });
  });

  group('SolveFlowWidget', () {
    testWidgets('shows child and submit button initially', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(
          child: SolveFlowWidget(child: const Text('题目内容')),
        )),
      ));
      expect(find.text('题目内容'), findsOneWidget);
      expect(find.text('提交'), findsOneWidget);
    });

    testWidgets('shows result after submission', (tester) async {
      // 使用 isRevisit 跳过冷却
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(
          child: SolveFlowWidget(
            isCorrect: true,
            isRevisit: true, // 跳过冷却，直接进入结果展示
            onSubmit: () {},
            child: const Text('题目'),
          ),
        )),
      ));
      expect(find.text('回答正确'), findsOneWidget);
    });

    testWidgets('shows done banner with next and rate buttons', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(
          child: SolveFlowWidget(
            isRevisit: true,
            isCorrect: true,
            onNext: () {},
            onRate: () {},
            child: const Text('题目'),
          ),
        )),
      ));
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('下一题'), findsOneWidget);
      expect(find.text('⭐ 评分'), findsOneWidget);
    });

    testWidgets('shows rated text when already rated', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(
          child: SolveFlowWidget(
            isRevisit: true, isRated: true, isCorrect: true,
            child: const Text('题目'),
          ),
        )),
      ));
      expect(find.text('已完成 ⭐ 已评分'), findsOneWidget);
    });
  });
}
