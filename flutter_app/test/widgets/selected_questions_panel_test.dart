import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/selected_questions_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());

  testWidgets('shows none, partial, and complete basket memberships', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SelectedQuestionsPanel(
            selectedCount: 4,
            items: const [
              SelectedQuestionsBasketItem(
                id: 1,
                name: '空状态篮',
                questionCount: 2,
                containedCount: 0,
              ),
              SelectedQuestionsBasketItem(
                id: 2,
                name: '半选状态篮',
                questionCount: 8,
                containedCount: 2,
              ),
              SelectedQuestionsBasketItem(
                id: 3,
                name: '全选状态篮',
                questionCount: 9,
                containedCount: 4,
              ),
            ],
            onCreateBasket: () async => null,
          ),
        ),
      ),
    );

    final tiles = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(tiles.map((tile) => tile.value), [false, null, true]);
    expect(find.text('将加入 0 个题次，并移除 0 个题次'), findsOneWidget);

    await tester.tap(find.text('半选状态篮'));
    await tester.pump();
    final updatedTiles = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(updatedTiles.elementAt(1).value, isTrue);
    expect(find.text('将加入 2 个题次，并移除 0 个题次'), findsOneWidget);
  });
}
