import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/exam_home_page.dart';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  group('ExamHomePage', () {
    testWidgets('renders the three paper center tabs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ExamHomePage()));
      expect(find.text('试卷中心'), findsOneWidget);
      expect(find.text('我创建的'), findsOneWidget);
      expect(find.text('发现试卷'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
      expect(find.byTooltip('新建试卷'), findsOneWidget);
      expect(find.text('试题篮'), findsNothing);
      expect(find.text('套卷'), findsNothing);
    });
  });
}
