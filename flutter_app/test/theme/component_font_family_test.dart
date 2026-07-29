import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  testWidgets('ListTile and AppButton use the bundled app font', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              const ListTile(title: Text('关于页面标题')),
              AppButton(label: '更新', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    expect(
      richTexts.any(
        (widget) =>
            widget.text.toPlainText() == '关于页面标题' &&
            widget.text.style?.fontFamily == AppTheme.fontFamily,
      ),
      isTrue,
    );
    expect(
      richTexts.any(
        (widget) =>
            widget.text.toPlainText() == '更新' &&
            widget.text.style?.fontFamily == AppTheme.fontFamily,
      ),
      isTrue,
    );
  });
}
