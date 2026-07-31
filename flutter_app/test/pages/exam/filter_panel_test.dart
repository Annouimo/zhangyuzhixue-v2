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
      expect(find.text('试题来源'), findsOneWidget);
      expect(find.text('年份'), findsOneWidget);
      expect(find.text('地区'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
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
      expect(find.text('概念标签'), findsOneWidget);
      expect(find.text('代数'), findsNothing);
      await tester.tap(find.text('概念标签'));
      await tester.pumpAndSettle();
      expect(find.text('代数'), findsOneWidget);
    });

    testWidgets('feature tab exposes difficulty controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterPanel(yearOptions: [], regionOptions: []),
            ),
          ),
        ),
      );
      expect(find.text('难度范围'), findsNothing);
      await tester.tap(find.text('题目特征'));
      await tester.pumpAndSettle();
      expect(find.text('难度范围'), findsOneWidget);
      expect(find.text('计算量范围'), findsOneWidget);
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

    testWidgets('grouped layout keeps summary, tabs and local reset in sync', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterPanel(
                yearOptions: const ['2025'],
                regionOptions: const ['北京'],
                onLoadPreference: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('筛选方案'), findsOneWidget);
      expect(find.text('概念标签'), findsOneWidget);
      expect(find.text('知识卡片'), findsOneWidget);
      expect(find.text('试题来源'), findsOneWidget);
      expect(find.text('题目特征'), findsOneWidget);
      expect(find.text('清除全部'), findsOneWidget);
      expect(find.text('清除当前维度'), findsNothing);

      await tester.tap(find.text('试题来源'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();

      expect(find.text('清除当前维度'), findsOneWidget);

      await tester.tap(find.text('清除当前维度'));
      await tester.pumpAndSettle();
      expect(find.text('清除当前维度'), findsNothing);
      expect(find.text('清除全部'), findsOneWidget);
    });
  });
}
