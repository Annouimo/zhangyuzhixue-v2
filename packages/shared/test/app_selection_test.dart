import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  test('selection controller manages and retains generic ids', () {
    final controller = AppSelectionController<String>();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.toggle('a');
    controller.selectAll(const ['a', 'b', 'c']);
    expect(controller.selectedIds, const {'a', 'b', 'c'});

    controller.retain(const ['b', 'c']);
    expect(controller.selectedIds, const {'b', 'c'});

    controller.clear();
    expect(controller.isEmpty, isTrue);
    expect(notifications, 4);
  });

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Column(children: [const Spacer(), child])),
  );

  testWidgets('action bar stays hidden without a selection', (tester) async {
    await tester.pumpWidget(
      host(
        AppSelectionActionBar(
          selectedCount: 0,
          totalCount: 189,
          itemUnit: ' 道题',
          onSelectAll: () {},
          onClear: () {},
          actionLabel: '加入试题篮',
          onAction: null,
        ),
      ),
    );

    expect(find.text('全选 189 道题'), findsNothing);
    expect(find.text('加入试题篮'), findsNothing);
  });

  testWidgets('partial selection offers select all and the primary action', (
    tester,
  ) async {
    var selectedAll = false;
    var actionInvoked = false;
    await tester.pumpWidget(
      host(
        AppSelectionActionBar(
          selectedCount: 2,
          totalCount: 189,
          itemUnit: ' 道题',
          onSelectAll: () => selectedAll = true,
          onClear: () {},
          actionLabel: '加入试题篮',
          onAction: () => actionInvoked = true,
        ),
      ),
    );

    expect(find.text('全选 189 道题'), findsOneWidget);
    expect(find.text('已选 2 道题'), findsOneWidget);
    await tester.tap(find.text('全选 189 道题'));
    await tester.tap(find.text('加入试题篮'));
    expect(selectedAll, isTrue);
    expect(actionInvoked, isTrue);
  });

  testWidgets('complete selection offers clear all', (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      host(
        AppSelectionActionBar(
          selectedCount: 189,
          totalCount: 189,
          itemUnit: ' 道题',
          onSelectAll: () {},
          onClear: () => cleared = true,
          actionLabel: '加入试题篮',
          onAction: () {},
        ),
      ),
    );

    expect(find.text('取消全选'), findsOneWidget);
    expect(find.text('已选 189 道题'), findsOneWidget);
    await tester.tap(find.text('取消全选'));
    expect(cleared, isTrue);
  });

  testWidgets('selection toggle exposes consistent semantics', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      host(
        AppSelectionToggle(
          selected: selected,
          onPressed: () => selected = true,
          selectTooltip: '选择题目',
        ),
      ),
    );

    await tester.tap(find.byTooltip('选择题目'));
    expect(selected, isTrue);
  });
}
