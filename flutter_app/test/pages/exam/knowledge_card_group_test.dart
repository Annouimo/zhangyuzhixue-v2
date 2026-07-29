import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('compact knowledge groups preview and search the full list', (
    tester,
  ) async {
    var selected = <String>{};
    final cards = List.generate(
      15,
      (index) => KnowledgeCardItem(id: index, title: '卡片 $index'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => KnowledgeCardGroupView(
              groups: [KnowledgeCardGroup(category: '流程', cards: cards)],
              selectedTitles: selected,
              compact: true,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('流程'));
    await tester.pumpAndSettle();
    expect(find.text('卡片 9'), findsOneWidget);
    expect(find.text('卡片 10'), findsNothing);

    await tester.tap(find.text('查看全部 15 项'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '卡片 14');
    await tester.pumpAndSettle();
    final result = find.widgetWithText(CheckboxListTile, '卡片 14');
    expect(result, findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, '卡片 1'), findsNothing);

    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(selected, contains('卡片 14'));
  });
}
