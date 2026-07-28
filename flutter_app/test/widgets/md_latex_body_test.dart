import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/md_latex_body.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('renders plain text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MdLatexBody('hello world'))),
    );
    await tester.pump();
    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('plain markdown inherits the app font family', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: MdLatexBody('统一字体')),
      ),
    );
    await tester.pump();

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    expect(
      richTexts.any(
        (widget) => widget.text.style?.fontFamily == AppTheme.fontFamily,
      ),
      isTrue,
    );
  });

  testWidgets('renders inline LaTeX', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MdLatexBody(r'公式$x^2$测试'))),
    );
    await tester.pump();
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('renders set notation without exposing markdown escapes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MdLatexBody(
            r'集合：$\{a, b, c\}$；真子集：$A \subsetneq B \land A \neq B$',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Math), findsAtLeastNWidgets(2));
    expect(find.textContaining(r'\{'), findsNothing);
    expect(find.textContaining(r'\neq'), findsNothing);
  });

  testWidgets('keeps relation formula readable at narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: MdLatexBody(
              r'关系：$A \subsetneq B \iff A \subseteq B \land A \neq B$',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsWidgets);
  });

  testWidgets('renders fill underline as an inline answer blank', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: MdLatexBody(
              r'函数$f(x)$的定义域是$\underline{\hspace{2cm}}$',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final blank = find.bySemanticsLabel('答题空格');
    expect(blank, findsOneWidget);
    expect(tester.getSize(blank).width, closeTo(79.6, 0.5));
    expect(find.textContaining(r'\underline'), findsNothing);
  });

  testWidgets('keeps underline with content as regular LaTeX', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MdLatexBody(r'$\underline{x+1}$'))),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('答题空格'), findsNothing);
    expect(find.byType(Math), findsWidgets);
  });

  testWidgets('does not accept legacy escaped underscore blanks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MdLatexBody(r'解集为\\_\\_\\_\\_\\_。'))),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('答题空格'), findsNothing);
  });

  testWidgets('renders bold', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MdLatexBody(r'**粗体**'))),
    );
    await tester.pump();
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('粗体'), findsOneWidget);
  });

  testWidgets('renders block LaTeX', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MdLatexBody(r'块级$$a^2+b^2=c^2$$公式'))),
    );
    await tester.pump();
    expect(find.textContaining(r'$$'), findsNothing);
  });

  testWidgets('keeps block formula readable with horizontal scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: MdLatexBody(
              r'$$\sum_{k=1}^{n}(a_k+b_k+c_k+d_k+e_k+f_k)=S_n$$',
            ),
          ),
        ),
      ),
    );
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
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MdLatexBody(''))));
    await tester.pump();
  });
}
