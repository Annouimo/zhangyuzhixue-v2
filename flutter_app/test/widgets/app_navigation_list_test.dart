import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('navigation list uses lightweight rows and inset dividers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox(
            width: 680,
            child: AppNavigationList(
              children: [
                AppNavigationListItem(
                  icon: Icons.looks_one_outlined,
                  title: '第一个',
                  subtitle: '第一项说明',
                ),
                AppNavigationListItem(
                  icon: Icons.looks_two_outlined,
                  title: '第二个',
                  subtitle: '第二项说明',
                ),
                AppNavigationListItem(
                  icon: Icons.looks_3_outlined,
                  title: '第三个',
                  subtitle: '第三项说明',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AppNavigationListItem), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.byType(Card), findsNothing);
    expect(find.byType(AppCard), findsNothing);
    expect(
      tester.getSize(find.byType(AppNavigationListItem).first).height,
      greaterThanOrEqualTo(88),
    );

    final divider = tester.getRect(find.byType(Divider).first);
    final list = tester.getRect(find.byType(AppNavigationList));
    expect(divider.left - list.left, 72);
    expect(list.right - divider.right, AppSpacing.md);
  });

  testWidgets('navigation item is clickable and exposes button semantics', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppNavigationListItem(
            icon: Icons.school_outlined,
            title: '学习档案',
            subtitle: '复盘、统计与做题记录',
            semanticLabel: '打开学习档案',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    await tester.tap(find.text('学习档案'));
    expect(taps, 1);

    final semantics = tester.getSemantics(find.byType(AppNavigationListItem));
    expect(semantics.label, '打开学习档案');
    expect(semantics.flagsCollection.isButton, isTrue);
  });

  testWidgets('navigation item applies recommendation tone to its icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppNavigationListItem(
            icon: Icons.auto_awesome_rounded,
            title: '推荐练习',
            subtitle: '安排适合当前阶段的练习',
            tone: AppStatusTone.recommendation,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome_rounded));
    expect(
      icon.color,
      AppTheme.light.extension<AppSemanticColors>()!.recommendation,
    );
  });
}
