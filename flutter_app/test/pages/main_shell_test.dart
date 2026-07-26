import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/pages/main_shell.dart';
import 'dart:io';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  late Directory tempDir;

  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(500, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
  }

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
    testWidgets('renders 4 bottom navigation tabs (首页/推荐/组卷/我的)', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('首页'), findsAtLeastNWidgets(1));
      expect(find.text('推荐'), findsOneWidget);
      expect(find.text('组卷'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('default tab is home (index 0)', (tester) async {
      await pumpShell(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });

    testWidgets('tapping recommend tab switches content', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('推荐'));
      await tester.pump();
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });

    testWidgets('tapping profile tab switches content', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('我的'));
      await tester.pump();
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 3);
    });

    testWidgets('tapping exam tab switches content', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('组卷'));
      await tester.pump();
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('uses side navigation on wide screens', (tester) async {
      await pumpShell(tester, size: const Size(1200, 800));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
