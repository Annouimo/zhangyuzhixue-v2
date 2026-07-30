import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  Future<void> pumpOption(WidgetTester tester, String content) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: QuestionOptionRow(label: 'A', content: content),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('aligns label and content regions at the top', (tester) async {
    await pumpOption(tester, '普通文本选项');

    final labelTop = tester
        .getTopLeft(find.byKey(QuestionOptionRow.labelRegionKey))
        .dy;
    final contentTop = tester
        .getTopLeft(find.byKey(QuestionOptionRow.contentRegionKey))
        .dy;

    expect(labelTop, contentTop);
  });

  testWidgets('keeps wrapped content inside the content column', (
    tester,
  ) async {
    await pumpOption(tester, '这是一段足够长的选项内容，用于验证换行以后仍然保持悬挂缩进。');

    final label = tester.getRect(find.byKey(QuestionOptionRow.labelRegionKey));
    final content = tester.getRect(
      find.byKey(QuestionOptionRow.contentRegionKey),
    );

    expect(content.left, greaterThan(label.right));
    expect(content.height, greaterThan(30));
  });

  testWidgets('removes migrated leading and trailing whitespace', (
    tester,
  ) async {
    await pumpOption(tester, '\n\n  选项正文  \n\n');

    final body = tester.widget<MdLatexBody>(find.byType(MdLatexBody));
    expect(body.data, '选项正文');
  });

  testWidgets('renders inline and block formula options', (tester) async {
    await pumpOption(tester, r'分式 $\frac{1}{2}$');
    expect(tester.takeException(), isNull);

    await pumpOption(tester, r'$$x^2+y^2=1$$');

    expect(tester.takeException(), isNull);
    expect(find.byType(MdLatexBody), findsOneWidget);
  });
}
