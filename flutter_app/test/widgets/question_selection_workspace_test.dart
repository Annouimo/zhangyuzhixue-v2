import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/question_selection_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());

  testWidgets('shared question list opens and selects independently', (
    tester,
  ) async {
    QuestionWorkspaceItem? opened;
    QuestionWorkspaceItem? toggled;
    const item = QuestionWorkspaceItem(
      id: 7,
      title: '共享题目',
      questionType: 'choice',
      subtitle: '2025 · 全国卷',
      difficulty: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionWorkspace(
            items: const [item],
            onOpen: (value) => opened = value,
            onSelectionChanged: (ids) {
              if (ids.contains(item.id)) toggled = item;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('共享题目'));
    expect(opened?.id, 7);

    await tester.tap(find.byTooltip('选择题目'));
    expect(toggled?.id, 7);
  });

  testWidgets('workspace owns the transient selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestionWorkspace(
            items: [
              QuestionWorkspaceItem(
                id: 3,
                title: '可选择题目',
                questionType: 'fill',
              ),
            ],
            onOpen: _ignoreQuestion,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('选择题目'));
    await tester.pump();
    expect(find.byTooltip('取消选择'), findsOneWidget);
  });

  test('question controller keeps the shared selection contract', () {
    final controller = QuestionWorkspaceController();
    controller.selectAll(const [1, 2, 3]);
    expect(controller.selectedIds, const {1, 2, 3});
    controller.retain(const [2, 3]);
    expect(controller.selectedIds, const {2, 3});
  });
}

void _ignoreQuestion(QuestionWorkspaceItem _) {}
