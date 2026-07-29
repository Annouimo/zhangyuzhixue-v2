import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/pdf_guide_dialog.dart';

void main() {
  testWidgets('mobile print guide uses a two plus one button layout', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPdfGuideDialog(context),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    final cancelCenter = tester.getCenter(find.text('取消'));
    final openCenter = tester.getCenter(find.text('仍在手机打开'));
    final copyCenter = tester.getCenter(find.text('复制链接，发送到电脑'));

    expect((cancelCenter.dy - openCenter.dy).abs(), lessThan(1));
    expect(copyCenter.dy, greaterThan(cancelCenter.dy));
    debugDefaultTargetPlatformOverride = null;
  });
}
