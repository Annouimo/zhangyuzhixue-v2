import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/pages/solve/solve_step_page.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('solve_step_page_test_');
    final provider = DatabaseProvider();
    await provider.initWithPath(tempDir.path);
  });

  tearDown(() async {
    await DatabaseProvider().reset();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SolveStepPage', () {
    testWidgets('renders loading state initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SolveStepPage(questionId: 1, methodIndex: 0, stepIndex: 0),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
