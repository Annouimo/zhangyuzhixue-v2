import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../support/ui_test_harness.dart';
import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  group('responsive page spacing', () {
    test('uses compact and expanded page gutters', () {
      expect(AppPagePadding.horizontalFor(390), AppSpacing.md);
      expect(AppPagePadding.horizontalFor(1280), AppSpacing.lg);
    });

    for (final viewport in UiTestViewport.values) {
      testWidgets('${viewport.name} applies its page gutter', (tester) async {
        const markerKey = Key('page-content');
        await pumpUiScenario(
          tester,
          const Scaffold(
            body: AppContentContainer(
              useSafeArea: false,
              child: SizedBox(key: markerKey),
            ),
          ),
          viewport: viewport,
        );

        final paddingFinder = find.ancestor(
          of: find.byKey(markerKey),
          matching: find.byType(Padding),
        );
        final padding = tester.widget<Padding>(paddingFinder.first).padding;
        expect(
          padding,
          EdgeInsets.symmetric(
            horizontal: AppPagePadding.horizontalFor(viewport.size.width),
          ),
        );
      });
    }
  });

  group('interactive shared surfaces', () {
    for (final theme in UiTestTheme.values) {
      testWidgets('card exposes feedback and semantics in ${theme.name}', (
        tester,
      ) async {
        var taps = 0;
        final semantics = tester.ensureSemantics();

        await pumpUiScenario(
          tester,
          Scaffold(
            body: AppCard(
              semanticLabel: '打开学习任务',
              onTap: () => taps++,
              child: const Text('学习任务'),
            ),
          ),
          theme: theme,
        );

        expect(find.byType(InkWell), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(AppCard)),
          matchesSemantics(
            label: '打开学习任务',
            isButton: true,
            isFocusable: true,
            hasTapAction: true,
          ),
        );
        await tester.tap(find.text('学习任务'));
        expect(taps, 1);
        semantics.dispose();
      });
    }

    testWidgets('section action uses a focusable material interaction', (
      tester,
    ) async {
      var taps = 0;
      await pumpUiScenario(
        tester,
        Scaffold(
          body: AppSectionHeader(
            title: '今日任务',
            actionLabel: '查看全部',
            onActionTap: () => taps++,
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AppSectionHeader),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('查看全部'));
      expect(taps, 1);
    });
  });
}
