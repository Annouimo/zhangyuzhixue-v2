import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('toast exposes semantic message and action', (tester) async {
    var acted = false;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppToast.warning(
              context,
              '数据尚未同步',
              actionLabel: '查看',
              onAction: () => acted = true,
            ),
            child: const Text('显示'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('数据尚未同步'), findsOneWidget);
    final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    action.onPressed();
    expect(acted, isTrue);
  });

  testWidgets('action sheet returns the selected mobile action', (
    tester,
  ) async {
    String? selected;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await AppActionSheet.show<String>(
                context,
                title: '操作',
                items: const [
                  AppActionSheetItem(
                    value: 'edit',
                    label: '编辑',
                    icon: Icons.edit_outlined,
                  ),
                ],
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(selected, 'edit');
  });

  testWidgets('action sheet uses a dialog on desktop', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppActionSheet.show<String>(
              context,
              items: const [
                AppActionSheetItem(
                  value: 'delete',
                  label: '删除',
                  icon: Icons.delete_outline,
                  destructive: true,
                ),
              ],
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });
}
