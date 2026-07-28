import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/exam_home_page.dart';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  group('ExamHomePage', () {
    testWidgets('renders paper management without duplicate creation buttons', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ExamHomePage()));
      expect(find.text('我的试卷'), findsWidgets);
      expect(find.text('试卷空间'), findsOneWidget);
      expect(find.textContaining('智能组卷'), findsNothing);
      expect(find.textContaining('自主选题'), findsNothing);
      expect(find.text('我的组卷'), findsAtLeastNWidgets(1));
      expect(find.text('发现组卷'), findsAtLeastNWidgets(1));
      expect(find.text('我的收藏'), findsAtLeastNWidgets(1));
    });
  });
}
