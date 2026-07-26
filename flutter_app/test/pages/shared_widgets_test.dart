import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import '../test_setup.dart';

void main() {
  setUp(() => setupTestHooks());
  group('LoadingIndicator', () {
    testWidgets('renders loading spinner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingIndicator())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(message: '加载中...')),
        ),
      );

      expect(find.text('加载中...'), findsOneWidget);
    });
  });

  group('ErrorPlaceholder', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorPlaceholder(message: '出错了')),
        ),
      );

      expect(find.text('出错了'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorPlaceholder(message: '出错了', onRetry: () {}),
          ),
        ),
      );

      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('does not render retry button when onRetry is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorPlaceholder(message: '出错了')),
        ),
      );

      expect(find.text('重试'), findsNothing);
    });
  });

  group('EmptyPlaceholder', () {
    testWidgets('renders empty message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmptyPlaceholder(message: '暂无数据')),
        ),
      );

      expect(find.text('暂无数据'), findsOneWidget);
    });
  });
}
