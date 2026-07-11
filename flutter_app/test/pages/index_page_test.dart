import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/index_page.dart';

void main() {
  group('IndexPage', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.text('章鱼智学'), findsOneWidget);
    });

    testWidgets('shows loading indicator on first frame', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IndexPage()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
