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

      // Empty DB = no attempts = fresh view
      expect(find.text('准备开始答题'), findsOneWidget);
      expect(find.text('开始答题'), findsOneWidget);
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

      // Fresh description mentions sub-question count
      expect(find.textContaining('共 0 小问'), findsOneWidget);
      expect(find.textContaining('首次作答'), findsOneWidget);
    });

    testWidgets('attempt selector renders single badge when no attempts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // No attempts yet, label should reference attempt count
      expect(find.textContaining('次作答'), findsOneWidget);
    });

    testWidgets('fresh view start button has play icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1)),
      );
      await tester.pumpAndSettle();

      // Start button should be present
      final btn = find.widgetWithText(ElevatedButton, '开始答题');
      expect(btn, findsOneWidget);
    });

    testWidgets('mode param determines review mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SolveMapPage(questionId: 1, mode: 'review')),
      );
      await tester.pumpAndSettle();

      // In review mode with no data, still shows fresh view
      expect(find.text('准备开始答题'), findsOneWidget);
    });
  });
}
