import 'package:flutter/material.dart';
import 'package:flutter_app/pages/exam/widgets/paper_action_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  Widget buildBar({required double width, VoidCallback? onSecondary}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: PaperActionBar(
              actions: [
                PaperAction(
                  label: '开始计时',
                  compactLabel: '开始',
                  icon: Icons.timer_outlined,
                  variant: AppButtonVariant.primary,
                  onPressed: () {},
                ),
                PaperAction(
                  label: '快速对答案',
                  icon: Icons.fact_check_outlined,
                  onPressed: onSecondary ?? () {},
                ),
              ],
              menuActions: const [
                PaperMenuAction(
                  value: 'print',
                  label: '打印试卷',
                  icon: Icons.print_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('wide bar keeps primary and secondary actions visible', (
    tester,
  ) async {
    await tester.pumpWidget(buildBar(width: 430));

    expect(find.text('开始计时'), findsOneWidget);
    expect(find.text('快速对答案'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('compact bar moves secondary action into overflow menu', (
    tester,
  ) async {
    var secondaryPressed = false;
    await tester.pumpWidget(
      buildBar(
        width: 190,
        onSecondary: () => secondaryPressed = true,
      ),
    );

    expect(find.text('开始'), findsOneWidget);
    expect(find.text('快速对答案'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('快速对答案'), findsOneWidget);
    expect(find.text('打印试卷'), findsOneWidget);

    await tester.tap(find.text('快速对答案'));
    await tester.pumpAndSettle();
    expect(secondaryPressed, isTrue);
  });
}
