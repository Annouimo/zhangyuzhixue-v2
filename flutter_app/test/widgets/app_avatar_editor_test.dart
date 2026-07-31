import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import 'package:flutter_app/widgets/app_avatar_editor.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('avatar editor exposes one labeled tap target', (tester) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(AppAvatarEditor(onPressed: () => taps++, fallback: const Text('张'))),
    );

    expect(find.byTooltip('更换头像'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppAvatarEditor)),
      matchesSemantics(
        label: '更换头像',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(AppAvatarEditor));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('uploading avatar is disabled and shows progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppAvatarEditor(
          onPressed: () {},
          uploading: true,
          fallback: const Icon(Icons.person),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
