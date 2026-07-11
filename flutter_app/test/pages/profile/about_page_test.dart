import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/profile/about_page.dart';

void main() {
  testWidgets('AboutPage renders version and links', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const AboutPage()));
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('版本 2.0.0'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
  });
}
