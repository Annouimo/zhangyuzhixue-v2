import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/profile/achievement_page.dart';

void main() {
  testWidgets('AchievementPage renders achievement list', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const AchievementPage()));
    expect(find.text('初次练习'), findsOneWidget);
    expect(find.text('持续学习'), findsOneWidget);
    expect(find.text('答题达人'), findsOneWidget);
    expect(find.text('全对之星'), findsOneWidget);
  });
}
