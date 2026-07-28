import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('navigation cards share typography and stable height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppNavigationCard(
            icon: Icons.school_outlined,
            title: '学习档案',
            subtitle: '复盘、统计与做题记录',
            onTap: () {},
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('学习档案'));
    final subtitle = tester.widget<Text>(find.text('复盘、统计与做题记录'));
    expect(
      title.style?.fontSize,
      AppTheme.light.textTheme.titleSmall?.fontSize,
    );
    expect(
      subtitle.style?.fontSize,
      AppTheme.light.textTheme.bodySmall?.fontSize,
    );
    expect(
      tester.getSize(find.byType(AppNavigationCard)).height,
      greaterThanOrEqualTo(88),
    );
  });

  testWidgets('responsive grid gives sibling cards equal widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 680,
            child: AppResponsiveCardGrid(
              children: const [
                AppNavigationCard(
                  key: Key('first'),
                  icon: Icons.looks_one_outlined,
                  title: '第一个',
                  subtitle: '说明',
                ),
                AppNavigationCard(
                  key: Key('second'),
                  icon: Icons.looks_two_outlined,
                  title: '第二个',
                  subtitle: '说明',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('first'))).width,
      tester.getSize(find.byKey(const Key('second'))).width,
    );
  });
}
