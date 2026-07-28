import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/pages/profile/about_page.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import '../../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  testWidgets('AboutPage renders version and links', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs().init();
    await tester.pumpWidget(MaterialApp(home: AboutPage()));
    await tester.pump();
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('版本 1.2.0（公测版 Beta 1）'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('数据与同步'), findsOneWidget);
    expect(find.text('应用与支持'), findsOneWidget);
    expect(find.text('开源许可证'), findsOneWidget);
    expect(find.text('导出运行日志'), findsOneWidget);
  });
}
