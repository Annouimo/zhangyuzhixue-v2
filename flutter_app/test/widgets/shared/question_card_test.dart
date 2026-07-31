import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/widgets/question_card.dart';
import '../../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());

  group('QuestionCard', () {
    testWidgets('renders title with MdLatexBody', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '已知函数 f(x)',
          questionType: 'choice',
        ),
      )));
      expect(find.textContaining('已知函数'), findsOneWidget);
    });

    testWidgets('renders type tag and difficulty tag', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'fill',
          difficulty: 5.0,
        ),
      )));
      expect(find.text('填空题'), findsOneWidget);
      expect(find.text('中难'), findsOneWidget);
    });

    testWidgets('renders status tag', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
          status: 'completed',
        ),
      )));
      expect(find.text('已完成'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
          subtitle: '2025-03-15',
        ),
      )));
      expect(find.text('2025-03-15'), findsOneWidget);
    });

    testWidgets('renders reason', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'solution',
          reason: '正弦定理薄弱',
        ),
      )));
      expect(find.textContaining('正弦定理薄弱'), findsOneWidget);
    });

    testWidgets('selectable mode shows check circle when selected', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
          selectable: true,
          selected: true,
        ),
      )));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('selectable mode shows radio when not selected', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
          selectable: true,
          selected: false,
        ),
      )));
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    });

    testWidgets('default mode shows chevron', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
        ),
      )));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('custom trailing overrides default', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
          trailing: const Icon(Icons.star, size: 18),
        ),
      )));
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      int calls = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: QuestionCard(
          questionId: 1,
          title: '测试题',
          questionType: 'choice',
          onTap: () => calls++,
        ),
      )));
      await tester.tap(find.byType(InkWell));
      expect(calls, 1);
    });
  });
}
