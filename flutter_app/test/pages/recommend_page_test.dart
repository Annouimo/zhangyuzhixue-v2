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
    expect(find.text('下一题'), findsOneWidget);
    expect(find.text('开始作答'), findsOneWidget);
    expect(find.text('巩固近期错题'), findsOneWidget);
  });

  testWidgets('next advances without showing a question list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendPage(
          recommendRepository: _MockRecommendRepo(
            smartList: [_question(1), _question(2)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一题'));
    await tester.pump();

    final body = tester.widget<MdLatexBody>(find.byType(MdLatexBody));
    expect(body.data, contains('推荐题 2'));
    expect(find.text('2/2'), findsOneWidget);
  });
}
