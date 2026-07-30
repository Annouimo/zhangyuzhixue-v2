import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('confirm returns true and marks destructive action', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppDialog.confirm(
                context,
                title: '删除？',
                message: '删除后无法恢复。',
                confirmLabel: '删除',
                destructive: true,
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('删除？'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('prompt validates and trims input', (tester) async {
    String? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppDialog.prompt(
                context,
                title: '新建',
                validator: (value) => value.isEmpty ? '请输入名称' : null,
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pump();
    expect(find.text('请输入名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  测试方案  ');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, '测试方案');
  });
}
