import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/widgets/recommend_card.dart';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  group('RecommendCard', () {
    testWidgets('renders title, type tag, difficulty tag and reason', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendCard(
              title: '已知函数 f(x) 是周期函数',
              questionType: 'choice',
              difficulty: 5.0,
              reason: '薄弱概念：函数',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('已知函数'), findsOneWidget);
      expect(find.text('选择题'), findsOneWidget);
      expect(find.text('中难'), findsOneWidget);
      expect(find.textContaining('薄弱概念：函数'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendCard(
              title: '测试题',
              questionType: 'fill',
              difficulty: 2.0,
              reason: '测试',
              onTap: () => calls++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('测试题'));
      expect(calls, 1);
    });
  });
}
