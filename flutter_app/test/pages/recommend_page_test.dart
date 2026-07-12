import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/recommend_repository.dart';
import 'package:flutter_app/pages/recommend_page.dart';
import '../test_setup.dart';

class _MockRecommendRepo implements RecommendRepository {
  List<RecommendedQuestion> smartList;
  int presetCount;
  _MockRecommendRepo({this.smartList = const [], this.presetCount = 0});

  @override
  Future<List<RecommendedQuestion>> getSmartList() async => smartList;

  @override
  Future<List<RecommendPreset>> getPresets() async =>
    List.generate(presetCount, (i) => RecommendPreset(id: i + 1, name: '预设 ${i + 1}'));

  @override
  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async => [];
}

void main() {
    setUp(() => setupTestHooks());
  group('RecommendPage', () {
    testWidgets('shows loading then empty when no data', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RecommendPage(
        recommendRepository: _MockRecommendRepo(),
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('暂无推荐，先去组卷或做几道题吧'), findsOneWidget);
    });

    testWidgets('shows smart recommendations', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RecommendPage(
        recommendRepository: _MockRecommendRepo(smartList: [
          const RecommendedQuestion(id: 1, title: '已知函数 f(x)', questionType: 'choice',
            difficulty: 3.0, recommendReason: '薄弱概念：函数', status: 'pending'),
        ]),
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('已知函数'), findsOneWidget);
      expect(find.text('选择题'), findsOneWidget);
      expect(find.text('薄弱概念：函数'), findsOneWidget);
    });

    testWidgets('switches to preset when no smart data but presets exist', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RecommendPage(
        recommendRepository: _MockRecommendRepo(presetCount: 2),
      )));
      await tester.pumpAndSettle();
      expect(find.text('暂无推荐，先去组卷或做几道题吧'), findsOneWidget);
    });

    testWidgets('manually switches between smart and preset via pills', (tester) async {
      final repo = _MockRecommendRepo(smartList: [
        const RecommendedQuestion(id: 1, title: '智能题', questionType: 'choice',
          difficulty: 3.0, recommendReason: '薄弱', status: 'pending'),
      ], presetCount: 2);
      await tester.pumpWidget(MaterialApp(home: RecommendPage(recommendRepository: repo)));
      await tester.pumpAndSettle();
      // Initially shows smart recommendation
      expect(find.text('🔮 智能推荐'), findsOneWidget);
      expect(find.text('智能题'), findsOneWidget);

      // Tap the preset pill directly
      await tester.tap(find.text('📋 偏好推荐'));
      await tester.pumpAndSettle();
      // Switches to preset mode
      expect(find.text('📋 偏好推荐'), findsOneWidget);
    });
  });
}
