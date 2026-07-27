@Tags(['golden'])
library;

import 'package:flutter_app/domain/recommend_repository.dart';
import 'package:flutter_app/pages/login_page.dart';
import 'package:flutter_app/pages/recommend_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui_test_harness.dart';
import '../test_setup.dart';

class _GoldenRecommendRepository implements RecommendRepository {
  @override
  Future<List<RecommendedQuestion>> getSmartList() async => const [
    RecommendedQuestion(
      id: 1,
      title: '函数单调性与导数综合练习',
      questionType: 'choice',
      difficulty: 5,
      recommendReason: '近期函数题正确率偏低，建议先巩固单调性判断',
      status: 'pending',
    ),
    RecommendedQuestion(
      id: 2,
      title: '圆锥曲线离心率专项',
      questionType: 'fill',
      difficulty: 6,
      recommendReason: '连续两次在参数范围处失分',
      status: 'in_progress',
    ),
  ];

  @override
  Future<List<RecommendPreset>> getPresets() async => const [];

  @override
  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async =>
      const [];
}

void main() {
  setUp(setupTestHooks);

  for (final scenario in [
    (UiTestViewport.mobile, UiTestTheme.light),
    (UiTestViewport.desktop, UiTestTheme.dark),
  ]) {
    testWidgets('login ${scenario.$1.name} ${scenario.$2.name}', (
      tester,
    ) async {
      await pumpUiScenario(
        tester,
        const LoginPage(),
        viewport: scenario.$1,
        theme: scenario.$2,
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LoginPage),
        matchesGoldenFile(
          'baselines/login_${scenario.$1.name}_${scenario.$2.name}.png',
        ),
      );
    });

    testWidgets('recommendation ${scenario.$1.name} ${scenario.$2.name}', (
      tester,
    ) async {
      await pumpUiScenario(
        tester,
        RecommendPage(recommendRepository: _GoldenRecommendRepository()),
        viewport: scenario.$1,
        theme: scenario.$2,
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RecommendPage),
        matchesGoldenFile(
          'baselines/recommend_${scenario.$1.name}_${scenario.$2.name}.png',
        ),
      );
    });
  }
}
