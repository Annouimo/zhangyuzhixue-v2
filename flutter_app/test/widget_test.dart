import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App renders placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const ZhangyuzhixueApp());

    expect(find.text('章鱼智学 v2'), findsOneWidget);
  });
}
