import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/pages/profile/preference_list_page.dart';

class _MockPreferenceRepository implements PreferenceRepository {
  final List<PreferenceSummary> _results;

  _MockPreferenceRepository({List<PreferenceSummary>? results})
      : _results = results ?? [];

  @override
  Future<List<PreferenceSummary>> getList() async => _results;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<int> getCount() async => _results.length;

  @override
  Future<PreferenceFilter> getEdit(int id) async =>
      const PreferenceFilter(years: [], regions: [], conceptTags: []);

  @override
  Future<void> save({
    required String name,
    required PreferenceFilter filter,
  }) async {}
}

void main() {
  group('PreferenceListPage', () {
    testWidgets('renders loading state initially', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceListPage(preferenceRepository: repo),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders app bar with correct title', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceListPage(preferenceRepository: repo),
        ),
      );
      expect(find.text('学习偏好管理'), findsOneWidget);
    });

    testWidgets('renders FAB with correct label', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceListPage(preferenceRepository: repo),
        ),
      );
      expect(find.text('新建偏好'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty placeholder when no preferences', (tester) async {
      final repo = _MockPreferenceRepository(results: []);
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceListPage(preferenceRepository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('暂无学习偏好，快去创建一个吧'), findsOneWidget);
    });

    testWidgets('renders preference list after loading', (tester) async {
      final repo = _MockPreferenceRepository(results: [
        const PreferenceSummary(id: 1, name: '测试偏好', summary: '2025 · 导数 · 难度 2-8'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceListPage(preferenceRepository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('测试偏好'), findsOneWidget);
    });
  });
}
