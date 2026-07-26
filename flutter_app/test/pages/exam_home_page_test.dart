import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/exam_home_page.dart';
import '../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  group('ExamHomePage', () {
    testWidgets('renders exam home with buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExamHomePage()),
      );
      expect(find.text('组卷'), findsOneWidget);
      expect(find.text('智能组卷 · 10 积分'), findsOneWidget);
      expect(find.text('自主选题 · 20 积分'), findsOneWidget);
      expect(find.text('我的组卷'), findsAtLeastNWidgets(1));
      expect(find.text('发现组卷'), findsAtLeastNWidgets(1));
      expect(find.text('我的收藏'), findsAtLeastNWidgets(1));
    });
  });
}
