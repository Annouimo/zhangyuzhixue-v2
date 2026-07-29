import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  const nodes = [
    ConceptTagNode(
      id: 1,
      name: '代数',
      children: [
        ConceptTagNode(id: 2, name: '集合', parentId: 1),
        ConceptTagNode(id: 3, name: '函数', parentId: 1),
      ],
    ),
  ];

  testWidgets('tree starts collapsed and separates expand from select', (
    tester,
  ) async {
    var selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ConceptTagTreeView(
              nodes: nodes,
              selectedNames: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('代数'), findsOneWidget);
    expect(find.text('集合'), findsNothing);

    await tester.tap(find.byTooltip('展开代数'));
    await tester.pump();
    expect(find.text('集合'), findsOneWidget);
    expect(selected, isEmpty);

    await tester.tap(find.text('代数'));
    await tester.pump();
    expect(selected, {'代数', '集合', '函数'});
  });

  testWidgets('partial child selection displays indeterminate parent', (
    tester,
  ) async {
    var selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ConceptTagTreeView(
              nodes: nodes,
              selectedNames: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('展开代数'));
    await tester.pump();
    await tester.tap(find.text('集合'));
    await tester.pump();

    expect(selected, {'集合'});
    expect(find.byIcon(Icons.indeterminate_check_box), findsOneWidget);
  });

  testWidgets('selecting a collapsed parent does not expand its children', (
    tester,
  ) async {
    var selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ConceptTagTreeView(
              nodes: nodes,
              selectedNames: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('代数'));
    await tester.pump();

    expect(selected, {'代数', '集合', '函数'});
    expect(find.text('集合'), findsNothing);
    expect(find.byTooltip('展开代数'), findsOneWidget);
  });
}
