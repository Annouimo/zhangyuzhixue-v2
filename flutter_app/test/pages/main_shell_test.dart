import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/pages/main_shell.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('main_shell_test_');

    // Initialize DatabaseProvider with temp dir
    final provider = DatabaseProvider();
    await provider.initWithPath(tempDir.path);
  });

  tearDown(() async {
    await DatabaseProvider().reset();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MainShell', () {
    testWidgets('renders 4 bottom navigation tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('作业'), findsOneWidget);
      expect(find.text('讲义'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('default tab is home (index 0)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 0);
    });

    testWidgets('tapping homework tab switches content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      await tester.tap(find.text('作业'));
      await tester.pump();
      await tester.pump();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 1);
    });

    testWidgets('tapping profile tab switches content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      await tester.tap(find.text('我的'));
      await tester.pump();
      await tester.pump();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 3);
      // 我的 tab 现在显示 ProfilePage
    });

    testWidgets('tapping lecture tab switches content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainShell()),
      );

      await tester.tap(find.text('讲义'));
      await tester.pump();
      await tester.pump();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 2);
    });
  });
}
