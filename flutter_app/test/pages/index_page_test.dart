import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/index_page.dart';

void main() {
  group('IndexPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.text('章鱼智学'), findsOneWidget);
    });

    testWidgets('renders quick entry grid', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.text('🏠 快捷入口'), findsOneWidget);
      expect(find.text('智能推荐'), findsOneWidget);
      expect(find.text('自主选题'), findsOneWidget);
      expect(find.text('学习统计'), findsOneWidget);
    });

    testWidgets('renders recent study placeholder', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.text('📖 继续学习'), findsOneWidget);
    });
  });
}
