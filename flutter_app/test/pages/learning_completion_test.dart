import 'package:flutter/material.dart';
import 'package:flutter_app/pages/solve/widgets/done_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../support/ui_test_harness.dart';
import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  for (final scenario in [
    (UiTestViewport.mobile, UiTestTheme.light),
    (UiTestViewport.desktop, UiTestTheme.dark),
  ]) {
    testWidgets(
      '${scenario.$1.name} completion offers a clear return action',
      (tester) async {
        var finished = false;
        await pumpUiScenario(
          tester,
          Scaffold(
            body: DoneBanner(
              onRate: () {},
              onFinish: () => finished = true,
            ),
          ),
          viewport: scenario.$1,
          theme: scenario.$2,
        );

        expect(find.text('作答结果已经保存，可以返回继续学习。'), findsOneWidget);
        expect(find.text('给题目评分'), findsOneWidget);
        expect(find.text('完成并返回'), findsOneWidget);
        final finishButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, '完成并返回'),
        );
        expect(finishButton.variant, isNull);
        await tester.tap(find.text('完成并返回'));
        expect(finished, isTrue);
      },
    );
  }

  testWidgets('next question remains the primary completion action', (
    tester,
  ) async {
    await pumpUiScenario(
      tester,
      Scaffold(
        body: DoneBanner(onNext: () {}, onFinish: () {}),
      ),
    );

    expect(find.text('作答结果已经保存，可以继续完成下一题。'), findsOneWidget);
    expect(find.text('下一题'), findsOneWidget);
    expect(find.text('完成并返回'), findsNothing);
  });
}
