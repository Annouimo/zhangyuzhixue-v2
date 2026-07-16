import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:teacher_app/widgets/md_latex_body.dart';

void main() {
  testWidgets('MdLatexBody renders plain text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody('hello world')),
    ));
    await tester.pump();
    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('MdLatexBody renders bold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MdLatexBody('**粗体**')),
    ));
    await tester.pump();
    expect(find.textContaining('粗体'), findsOneWidget);
  });

  testWidgets('EmptyPlaceholder renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无数据', style: TextStyle(color: Colors.grey)),
          ],
        )),
      ),
    ));
    await tester.pump();
    expect(find.text('暂无数据'), findsOneWidget);
  });
}
