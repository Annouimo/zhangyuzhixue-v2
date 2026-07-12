import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/main.dart';
import 'test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  testWidgets('App renders login page on start', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs().init();

    await tester.pumpWidget(const ZhangyuzhixueApp());

    // Router 初始路由是 /login（无 token 时），显示登录页品牌标识
    expect(find.text('🐙 章鱼智学'), findsOneWidget);
    expect(find.text('📚 登录'), findsOneWidget);
  });
}
