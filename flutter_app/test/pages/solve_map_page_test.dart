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
  });
}
