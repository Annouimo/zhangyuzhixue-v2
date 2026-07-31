import 'package:flutter/material.dart';
import 'package:flutter_app/pages/content_home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('shows lecture and video catalog entrances', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ContentHomePage()));

    expect(find.text('讲义'), findsOneWidget);
    expect(find.text('视频'), findsOneWidget);
    expect(find.text('筹备中'), findsNothing);
  });
}
