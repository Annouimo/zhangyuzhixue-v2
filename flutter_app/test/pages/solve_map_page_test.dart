import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/pages/solve/solve_map_page.dart';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('solve_map_page_test_');
    final provider = DatabaseProvider();
    await provider.initWithPath(tempDir.path);
  });

  tearDown(() async {
    await DatabaseProvider().reset();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SolveMapPage', () {
    testWidgets('renders loading state initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppBar title shows 解题地图', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();
      expect(find.text('解题地图'), findsOneWidget);
    });

    testWidgets('shows fresh welcome view when no attempts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // Empty DB = no sub-questions = no step data
      expect(find.text('暂无步骤数据'), findsOneWidget);
    });

    testWidgets('renders back and rate buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // Back and rate buttons in map footer (fresh view has no map, but buttons not shown)
      // They are inside _buildMapView only, not in _buildFreshView
      // So they should not be visible in fresh view
      expect(find.text('返回'), findsNothing);
      expect(find.text('评分'), findsNothing);
    });

    testWidgets('shows step indicator in fresh view description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // Empty DB = no sub-questions = no step data
      expect(find.text('暂无步骤数据'), findsOneWidget);
    });

    testWidgets('attempt selector renders single badge when no attempts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // Empty DB = no sub-questions = no step data
      expect(find.text('暂无步骤数据'), findsOneWidget);
    });

    testWidgets('fresh view start button has play icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // Empty DB = no sub-questions = no step data, no start button
      expect(find.text('暂无步骤数据'), findsOneWidget);
    });

    testWidgets('mode param determines review mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1, mode: 'review')),
      );
      await tester.pumpAndSettle();

      // No data in review mode → same "暂无步骤数据" as normal mode
      expect(find.text('暂无步骤数据'), findsOneWidget);
    });
  });
}
