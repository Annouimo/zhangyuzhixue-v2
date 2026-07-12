import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/pages/index_page.dart';
import 'package:flutter_app/widgets/shared/error_placeholder.dart';
import '../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  group('IndexPage', () {
    testWidgets('renders app bar with title 首页', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.text('首页'), findsOneWidget);
    });

    testWidgets('shows loading indicator on first frame', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error placeholder when load fails', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      // 推进时钟让 _load 的异步操作完成（无数据库环境，DAO 将失败）
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ErrorPlaceholder), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
    });
  });
}
