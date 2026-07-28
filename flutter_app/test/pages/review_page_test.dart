import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/review_repository.dart';
import 'package:flutter_app/pages/review_page.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

class _ReviewRepository implements ReviewRepository {
  @override
  Future<List<ConceptProgress>> getConceptProgress() async => const [
    ConceptProgress(
      name: '函数单调性',
      attemptCount: 3,
      accuracy: 0.33,
      status: ConceptProgressStatus.needsReview,
    ),
  ];
}

void main() {
  setUp(setupTestHooks);

  testWidgets('review only shows concept status without sibling shortcuts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewPage(reviewRepository: _ReviewRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('函数单调性'), findsOneWidget);
    expect(find.text('学习统计'), findsNothing);
    expect(find.text('做题记录'), findsNothing);
  });
}
