import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/md_latex_body.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('renders plain text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody('hello world')),
    ));
    await tester.pump();
    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('renders inline LaTeX', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody(r'公式$x^2$测试')),
    ));
    await tester.pump();
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('renders bold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody(r'**粗体**')),
    ));
    await tester.pump();
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('粗体'), findsOneWidget);
  });

  testWidgets('renders block LaTeX', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody(r'块级$$a^2+b^2=c^2$$公式')),
    ));
    await tester.pump();
    expect(find.textContaining(r'$$'), findsNothing);
  });

  testWidgets('keeps block formula readable with horizontal scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 240,
          child: MdLatexBody(
            r'$$\sum_{k=1}^{n}(a_k+b_k+c_k+d_k+e_k+f_k)=S_n$$',
          ),
        ),
      ),
    ));
    await tester.pump();

    final horizontalScroll = tester.widgetList<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(
      horizontalScroll.any((view) => view.scrollDirection == Axis.horizontal),
      isTrue,
    );
    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('handles empty data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody('')),
    ));
    await tester.pump();
  });
}
