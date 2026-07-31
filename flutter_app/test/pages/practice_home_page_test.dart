import 'package:flutter/material.dart';
import 'package:flutter_app/pages/practice_home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('shows learning and practice entrances', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PracticeHomePage()));

    expect(find.text('推荐练习'), findsOneWidget);
    expect(find.text('题库选题'), findsOneWidget);
    expect(find.text('错题本'), findsOneWidget);
    expect(find.text('学习资料'), findsOneWidget);
    expect(find.byType(AppNavigationList), findsOneWidget);
    expect(find.byType(AppNavigationListItem), findsNWidgets(4));
    expect(find.byType(Divider), findsNWidgets(3));
    expect(find.byType(AppCard), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });
}
