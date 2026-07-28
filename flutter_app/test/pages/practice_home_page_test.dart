import 'package:flutter/material.dart';
import 'package:flutter_app/pages/practice_home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('shows the three practice paths without top tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PracticeHomePage()));

    expect(find.text('推荐练习'), findsOneWidget);
    expect(find.text('题库浏览'), findsOneWidget);
    expect(find.text('试卷'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });
}
