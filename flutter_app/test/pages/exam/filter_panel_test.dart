import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/widgets/filter_panel.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import '../../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  group('FilterPanel', () {
    testWidgets('renders year and region chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterPanel(
                yearOptions: ['2025', '2024'],
                regionOptions: ['海淀', '西城'],
              ),
            ),
          ),
        ),
      );
      expect(find.text('按来源筛选'), findsOneWidget);
      // Expand source section to see year/region chips
      await tester.tap(find.text('按来源筛选'));
      await tester.pumpAndSettle();
      expect(find.text('年份'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('地区'), findsOneWidget);
      expect(find.text('海淀'), findsOneWidget);
      expect(find.text('西城'), findsOneWidget);
    });

    testWidgets('renders concept tag tree section when tree provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterPanel(
                yearOptions: [],
                regionOptions: [],
                conceptTagOptions: ['代数', '函数', '三角函数'],
                conceptTagTree: [
                  ConceptTagNode(
                    id: 1,
                    name: '代数',
                    children: [
                      ConceptTagNode(
                        id: 2,
                        name: '函数',
                        parentId: 1,
                        children: [
                          ConceptTagNode(id: 3, name: '三角函数', parentId: 2),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Section header visible even when collapsed
      expect(find.text('按概念标签筛选'), findsOneWidget);
      // Root node hidden when collapsed
      expect(find.text('代数'), findsNothing);
      // Tap to expand
      await tester.tap(find.text('按概念标签筛选'));
      await tester.pumpAndSettle();
      // Now root node visible
      expect(find.text('代数'), findsOneWidget);
    });

    testWidgets('difficulty section collapsed by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterPanel(yearOptions: [], regionOptions: []),
            ),
          ),
        ),
      );
      // Default collapsed: difficulty labels not visible
      expect(find.textContaining('基础'), findsNothing);
      expect(find.textContaining('压轴'), findsNothing);
      // Tap section header to expand
      await tester.tap(find.text('按难度/计算量筛选'));
      await tester.pumpAndSettle();
      // Now should be visible
      expect(find.textContaining('基础'), findsWidgets);
      expect(find.textContaining('压轴'), findsWidgets);
    });

    testWidgets('silent external updates do not emit duplicate changes', (
      tester,
    ) async {
      final key = GlobalKey<FilterPanelState>();
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterPanel(
              key: key,
              yearOptions: const ['2026'],
              regionOptions: const ['东城'],
              onChanged: (_) => changes++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = changes;

      key.currentState!.applyFilter(
        years: const {'2026'},
        regions: const {'东城'},
        notify: false,
      );
      await tester.pump();

      expect(changes, before);
    });
  });
}
