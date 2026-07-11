import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App renders login page on start', (WidgetTester tester) async {
    await tester.pumpWidget(const ZhangyuzhixueApp());

    // Router 初始路由是 /login，显示登录页品牌标识
    expect(find.text('🐙 章鱼智学'), findsOneWidget);
    expect(find.text('📚 登录'), findsOneWidget);
  });
}
