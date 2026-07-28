import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/recommend_repository.dart';
import 'package:flutter_app/pages/recommend_page.dart';
import 'package:shared/widgets/md_latex_body.dart';
import '../test_setup.dart';

class _MockRecommendRepo implements RecommendRepository {
  _MockRecommendRepo({this.smartList = const []});

  List<RecommendedQuestion> smartList;

  @override
  Future<List<RecommendedQuestion>> getSmartList() async => smartList;

  @override
  Future<List<RecommendPreset>> getPresets() async => [];

  @override
  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async => [];
}

RecommendedQuestion _question(int id) => RecommendedQuestion(
  id: id,
  title: '推荐题 $id：已知函数 f(x)',
  questionType: 'choice',
  difficulty: 3,
  recommendReason: id == 1 ? '巩固近期错题' : '拓展新的题目',
  status: 'pending',
);

Widget _solveBuilder(RecommendedQuestion question, VoidCallback onNext) {
  return Column(
    children: [
      MdLatexBody(question.title),
      TextButton(onPressed: onNext, child: const Text('完成并下一题')),
    ],
  );
}

void main() {
  setUp(setupTestHooks);

  testWidgets('shows loading then empty when no question is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendPage(recommendRepository: _MockRecommendRepo()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.textContaining('当前没有可推荐'), findsOneWidget);
  });

  testWidgets('shows exactly the current question and fixed actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendPage(
          recommendRepository: _MockRecommendRepo(
            smartList: [_question(1), _question(2)],
          ),
          solveBuilder: _solveBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<RecommendPageState>(find.byType(RecommendPage));
    expect(state.debugLoadError, isNull);
    expect(state.debugLoading, isFalse);
    expect(state.debugQueueLength, 2);
    final body = tester.widget<MdLatexBody>(find.byType(MdLatexBody));
    expect(body.data, contains('推荐题 1'));
    expect(find.byTooltip('换一题'), findsOneWidget);
    expect(find.text('作答'), findsNothing);
    expect(find.text('巩固近期错题'), findsOneWidget);
  });

  testWidgets('next advances without showing a question list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendPage(
          recommendRepository: _MockRecommendRepo(
            smartList: [_question(1), _question(2)],
          ),
          solveBuilder: _solveBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('换一题'));
    await tester.pump();

    final body = tester.widget<MdLatexBody>(find.byType(MdLatexBody));
    expect(body.data, contains('推荐题 2'));
    expect(find.text('2/2'), findsNothing);
  });

  testWidgets('background refresh keeps the current question', (tester) async {
    final repo = _MockRecommendRepo(smartList: [_question(1), _question(2)]);
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendPage(
          recommendRepository: repo,
          solveBuilder: _solveBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    repo.smartList = [_question(3), _question(2)];
    final state = tester.state<RecommendPageState>(find.byType(RecommendPage));
    await state.refresh();
    await tester.pump();

    expect(find.textContaining('推荐题 1'), findsOneWidget);
    await tester.tap(find.byTooltip('换一题'));
    await tester.pump();
    expect(find.textContaining('推荐题 3'), findsOneWidget);
  });
}
