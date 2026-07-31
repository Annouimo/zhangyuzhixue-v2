import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/exam_home_page.dart';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  group('ExamHomePage', () {
    testWidgets('renders exam entry points', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ExamHomePage()));
      expect(find.text('试卷'), findsOneWidget);
      expect(find.text('试题篮'), findsOneWidget);
      expect(find.text('浏览试卷'), findsOneWidget);
      expect(find.text('我的试卷'), findsOneWidget);
    });
  });
}
