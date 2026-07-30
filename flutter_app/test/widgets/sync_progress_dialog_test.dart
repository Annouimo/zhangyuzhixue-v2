import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';

void main() {
  testWidgets('failure actions render under the full-width button theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showSyncProgress(context, (_) async {
                throw StateError('sync failed');
              });
            },
            child: const Text('sync'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('sync'));
    await tester.pumpAndSettle();

    expect(find.text('同步失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
