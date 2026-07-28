import 'package:flutter/material.dart';
import 'package:flutter_app/pages/exam/exam_pick_page.dart';
import 'package:flutter_app/pages/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('redirects the legacy manual-pick page to the workspace', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/legacy-pick',
      routes: [
        GoRoute(
          path: '/legacy-pick',
          builder: (context, state) => const ExamPickPage(),
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
