import 'package:flutter_app/domain/recommend_repository.dart';
import 'package:flutter_app/pages/recommend_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import '../support/ui_test_harness.dart';
import '../test_setup.dart';

class _RecommendRepo implements RecommendRepository {
  @override
  Future<List<RecommendedQuestion>> getSmartList() async => const [
    RecommendedQuestion(
      id: 1,
      title: '函数单调性练习',
      questionType: 'choice',
      difficulty: 5,
      recommendReason: '近期函数题正确率偏低',
      status: 'pending',
    ),
  ];

  @override
  Future<List<RecommendPreset>> getPresets() async => const [];

  @override
  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async =>
      const [];
}

Widget _solveBuilder(RecommendedQuestion question, VoidCallback onNext) {
  return Center(child: MdLatexBody(question.title));
}

void main() {
  setUp(setupTestHooks);

  for (final scenario in [
    (UiTestViewport.mobile, UiTestTheme.light),
    (UiTestViewport.desktop, UiTestTheme.dark),
  ]) {
    testWidgets(
      '${scenario.$1.name} recommendation follows the shared visual language',
      (tester) async {
        await pumpUiScenario(
          tester,
          RecommendPage(
            recommendRepository: _RecommendRepo(),
            solveBuilder: _solveBuilder,
          ),
          viewport: scenario.$1,
          theme: scenario.$2,
        );
        await tester.pumpAndSettle();

        final state = tester.state<RecommendPageState>(
          find.byType(RecommendPage),
        );
        expect(state.debugLoadError, isNull);
        expect(state.debugLoading, isFalse);
        expect(state.debugQueueLength, 1);
        expect(find.byType(MdLatexBody), findsOneWidget);
        expect(find.text('作答'), findsNothing);

        final reasonText = find.textContaining('近期函数题正确率偏低');
        expect(reasonText, findsOneWidget);
      },
    );
  }
}
