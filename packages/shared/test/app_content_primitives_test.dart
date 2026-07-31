import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('AppSection remains a transparent content section', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppSection(title: '基本信息', child: Text('内容'))),
    );

    expect(find.text('基本信息'), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Material), findsOneWidget);
  });

  testWidgets('AppCallout exposes semantic content without a card', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const AppCallout(
          title: '审核意见',
          message: '请补充来源。',
          tone: AppCalloutTone.warning,
        ),
      ),
    );

    expect(find.text('审核意见'), findsOneWidget);
    expect(find.text('请补充来源。'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    final node = tester.getSemantics(find.byType(AppCallout));
    expect(node.label, contains('审核意见'));
    expect(node.label, contains('请补充来源。'));
    semantics.dispose();
  });

  testWidgets(
    'AppAsyncContent selects loading error empty and content states',
    (tester) async {
      Future<void> pump({
        required bool loading,
        required bool empty,
        String? error,
      }) => tester.pumpWidget(
        host(
          AppAsyncContent(
            loading: loading,
            empty: empty,
            error: error,
            child: const Text('正常内容'),
          ),
        ),
      );

      await pump(loading: true, empty: false);
      expect(find.text('正在加载'), findsOneWidget);

      await pump(loading: false, empty: false, error: '网络错误');
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('网络错误'), findsOneWidget);

      await pump(loading: false, empty: true);
      expect(find.text('暂无内容'), findsOneWidget);

      await pump(loading: false, empty: false);
      expect(find.text('正常内容'), findsOneWidget);
    },
  );

  testWidgets(
    'QuestionContent renders stem and ordered options without a card',
    (tester) async {
      await tester.pumpWidget(
        host(
          const QuestionContent(
            stem: r'已知函数 $f(x)$',
            options: {'A': '选项一', 'B': '选项二'},
          ),
        ),
      );

      expect(find.textContaining('已知函数'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    },
  );
}
