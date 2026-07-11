import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/pages/index_page.dart';

void main() {
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

    testWidgets('renders dashboard content after load', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      // 推进时钟让 _load 的异步操作完成
      await tester.pump(const Duration(milliseconds: 100));

      // 欢迎语卡片副标题
      expect(find.text('每天一句，保持节奏'), findsOneWidget);

      // 待办作业
      expect(find.text('待办作业'), findsOneWidget);

      // 讲义入口
      expect(find.text('讲义'), findsOneWidget);

      // 签到/任务卡片
      expect(find.text('签到'), findsOneWidget);
    });
  });
}
