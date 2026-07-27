import 'package:flutter/material.dart';
import 'package:flutter_app/pages/solve/widgets/knowledge_card_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../support/ui_test_harness.dart';
import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  for (final viewport in UiTestViewport.values) {
    testWidgets('${viewport.name} knowledge card stays within the viewport', (
      tester,
    ) async {
      await pumpUiScenario(
        tester,
        Scaffold(
          body: KnowledgeCardDialog(
            cardTitle: '导数的几何意义',
            cardContent: List.filled(
              18,
              r"函数在一点的导数表示切线斜率，且 $f'(x_0)=k$。",
            ).join('\n\n'),
          ),
        ),
        viewport: viewport,
        theme: viewport == UiTestViewport.mobile
            ? UiTestTheme.light
            : UiTestTheme.dark,
      );

      final dialogSize = tester.getSize(
        find.byKey(const Key('knowledge-card-surface')),
      );
      expect(dialogSize.height, lessThanOrEqualTo(viewport.size.height * 0.8));
      expect(dialogSize.width, lessThanOrEqualTo(AppContentWidth.reading));
      expect(find.text('这张知识卡你掌握得怎么样？'), findsOneWidget);
      expect(find.text('完全掌握'), findsOneWidget);
      expect(find.text('了解'), findsOneWidget);
      expect(find.text('不理解'), findsOneWidget);
    });
  }
}
