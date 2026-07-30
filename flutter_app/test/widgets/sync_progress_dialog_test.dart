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

  testWidgets('shows unresolved details and confirms force sync', (
    tester,
  ) async {
    var forced = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showSyncProgress(
                context,
                (_) async => throw StateError('sync failed'),
                unresolvedDetails: () async => ['试题篮 3 条', '组卷 1 条'],
                forceTask: (_) async => forced = true,
              );
            },
            child: const Text('sync'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('sync'));
    await tester.pumpAndSettle();
    expect(find.text('• 试题篮 3 条'), findsOneWidget);
    expect(find.text('• 组卷 1 条'), findsOneWidget);

    await tester.tap(find.text('放弃这些记录并同步'));
    await tester.pumpAndSettle();
    expect(find.text('放弃未同步记录？'), findsOneWidget);
    await tester.tap(find.text('确认放弃并同步'));
    await tester.pumpAndSettle();

    expect(forced, isTrue);
    expect(find.text('同步完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
