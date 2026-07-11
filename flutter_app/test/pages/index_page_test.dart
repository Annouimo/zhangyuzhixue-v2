import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/index_page.dart';

void main() {
  group('IndexPage', () {
    testWidgets('renders app bar with title 首页', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      // 新首页 AppBar 标题为「首页」
      expect(find.text('首页'), findsOneWidget);
    });

    testWidgets('shows loading indicator on first frame', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      // LoadingIndicator 内部渲染 CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders dashboard content after load', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      await tester.pumpAndSettle();

      // 欢迎语卡片（随机内容，只验证容器存在）
      expect(find.text('每天一句，保持节奏'), findsOneWidget);

      // 待办作业
      expect(find.text('待办作业'), findsOneWidget);
      expect(find.text('0 项未完成'), findsOneWidget);

      // 讲义入口
      expect(find.text('讲义'), findsOneWidget);
      expect(find.text('浏览课程与讲义内容'), findsOneWidget);

      // 签到/任务卡片
      expect(find.textContaining('已连续签到'), findsOneWidget);
      expect(find.text('签到'), findsOneWidget);
    });
  });
}
