import 'package:flutter/material.dart';
import 'package:flutter_app/pages/exam/exam_auto_page.dart';
import 'package:flutter_app/pages/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('redirects the legacy smart-paper page to the workspace', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/legacy-auto',
      routes: [
        GoRoute(
          path: '/legacy-auto',
          builder: (context, state) => const ExamAutoPage(),
        ),
        GoRoute(
          path: AppRoutes.questionBank,
          builder: (context, state) => const Scaffold(body: Text('统一工作台')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('统一工作台'), findsOneWidget);
  });
}
