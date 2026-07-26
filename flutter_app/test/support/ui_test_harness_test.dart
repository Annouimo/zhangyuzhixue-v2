import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_setup.dart';
import 'ui_test_harness.dart';

void main() {
  setUp(setupTestHooks);

  for (final viewport in UiTestViewport.values) {
    for (final theme in UiTestTheme.values) {
      testWidgets(
        '${viewport.name} ${theme.name} uses fixed viewport and theme',
        (tester) async {
          await pumpUiScenario(
            tester,
            const Scaffold(body: Text('UI baseline')),
            viewport: viewport,
            theme: theme,
          );

          final context = tester.element(find.text('UI baseline'));
          expect(MediaQuery.sizeOf(context), viewport.size);
          expect(
            Theme.of(context).brightness,
            theme == UiTestTheme.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  }
}
