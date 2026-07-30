import 'package:flutter/material.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/question_bank/paper_draft_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('groups by type and reorders only within a type', (tester) async {
    PaperDraft? result;
    const questions = [
      SearchQuestion(
        id: 3,
        title: '解答题',
        questionType: 'solution',
        meta: '',
        difficulty: 3,
        calculation: 2,
      ),
      SearchQuestion(
        id: 1,
        title: r'选择题一 $x^2$',
        questionType: 'choice',
        meta: '',
        difficulty: 3,
        calculation: 2,
      ),
      SearchQuestion(
        id: 2,
        title: '填空题',
        questionType: 'fill',
        meta: '',
        difficulty: 4,
        calculation: 3,
      ),
      SearchQuestion(
        id: 4,
        title: '选择题二',
        questionType: 'choice',
        meta: '',
        difficulty: 5,
        calculation: 4,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<PaperDraft>(
                  context: context,
                  builder: (_) => const PaperDraftDialog(
                    initialName: '原名称',
                    questions: questions,
                    cost: 10,
                  ),
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(MdLatexBody), findsWidgets);
    expect(find.text('选择题 · 2 题'), findsOneWidget);
    expect(find.text('填空题 · 1 题'), findsOneWidget);
    expect(find.text('解答题 · 1 题'), findsOneWidget);
    expect(find.text('按题型排序'), findsNothing);
    expect(find.byType(ReorderableListView), findsNWidgets(3));
    await tester.enterText(find.byType(TextField), '新试卷');

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView).first,
    );
    list.onReorderItem!(0, 1);
    await tester.pump();

    await tester.tap(find.text('确认生成 · 10 积分'));
    await tester.pumpAndSettle();

    expect(result?.name, '新试卷');
    expect(result?.questions.map((question) => question.id), [4, 1, 2, 3]);
  });
}
