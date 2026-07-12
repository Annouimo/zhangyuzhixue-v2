import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/exam/widgets/paper_card.dart';
import '../../test_setup.dart';

void main() {
    setUp(() => setupTestHooks());
  group('PaperCard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: PaperCard(title: '测试试卷', subtitle: '2025 海淀一模', onTap: () {}),
      )));
      expect(find.text('测试试卷'), findsOneWidget);
      expect(find.text('2025 海淀一模'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      int calls = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: PaperCard(title: '试卷', subtitle: '描述', onTap: () => calls++),
      )));
      await tester.tap(find.text('试卷'));
      expect(calls, 1);
    });
  });
}
