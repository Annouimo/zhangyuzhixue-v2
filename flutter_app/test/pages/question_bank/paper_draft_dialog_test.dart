import 'package:flutter/material.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/question_bank/paper_draft_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('edits title, order, and contents before confirming', (
    tester,
  ) async {
    PaperDraft? result;
    const questions = [
      SearchQuestion(
        id: 1,
        title: '第一题',
        questionType: 'choice',
        meta: '',
        difficulty: 3,
        calculation: 2,
      ),
      SearchQuestion(
        id: 2,
        title: '第二题',
        questionType: 'fill',
        meta: '',
        difficulty: 4,
        calculation: 3,
      ),
      SearchQuestion(
        id: 3,
        title: '第三题',
        questionType: 'solution',
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
                    cost: 20,
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
    await tester.enterText(find.byType(TextField), '新试卷');

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(0, 2);
    await tester.pump();

    await tester.tap(find.byTooltip('移除题目').at(1));
    await tester.pump();
    expect(find.text('共 2 题'), findsOneWidget);

    await tester.tap(find.text('确认生成 · 20 积分'));
    await tester.pumpAndSettle();

    expect(result?.name, '新试卷');
    expect(result?.questions.map((question) => question.id), [2, 1]);
  });
}
