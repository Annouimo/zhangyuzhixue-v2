import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/main_shell.dart';

void main() {
  group('MainShell', () {
    testWidgets('renders 4 bottom navigation tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      // 验证 4 个 tab 存在
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('作业'), findsOneWidget);
      expect(find.text('讲义'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('default tab is home (index 0)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      // 首页应该被选中
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 0);
    });

    testWidgets('tapping homework tab switches content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      // 点击「作业」tab
      await tester.tap(find.text('作业'));
      await tester.pumpAndSettle();

      // 作业 tab 被选中
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 1);
      // 占位页面显示"作业列表"
      expect(find.text('作业列表（Phase 3d）'), findsOneWidget);
    });

    testWidgets('tapping profile tab switches content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      // 点击「我的」tab
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 3);
      expect(find.text('个人中心（Phase 3h）'), findsOneWidget);
    });

    testWidgets('tapping lecture tab switches content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      await tester.tap(find.text('讲义'));
      await tester.pumpAndSettle();

      // 讲义 tab 被选中，IndexedStack 保持页面状态
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 2);
    });
  });
}
