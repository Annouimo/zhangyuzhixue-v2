import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/pages/profile/preference_list_page.dart';
import '../../test_setup.dart';

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
  Future<PreferenceEditData> getEdit(int id) async => const PreferenceEditData(
    name: '',
    filter: PreferenceFilter(years: [], regions: [], conceptTags: []),
  );

  @override
  Future<int> save({
    required String name,
    required PreferenceFilter filter,
    int? existingId,
  }) async => 0;
}

void main() {
  setUp(() => setupTestHooks());
  group('PreferenceListPage', () {
    testWidgets('renders loading state initially', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(home: PreferenceListPage(preferenceRepository: repo)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders app bar with correct title', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(home: PreferenceListPage(preferenceRepository: repo)),
      );
      expect(find.text('我的筛选方案'), findsOneWidget);
    });

    testWidgets('renders create action in the app bar', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(home: PreferenceListPage(preferenceRepository: repo)),
      );
      expect(find.text('新建方案'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('shows empty placeholder when no preferences', (tester) async {
      final repo = _MockPreferenceRepository(results: []);
      await tester.pumpWidget(
        MaterialApp(home: PreferenceListPage(preferenceRepository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('还没有筛选方案。可以把经常使用的查找条件保存到这里。'), findsOneWidget);
    });

    testWidgets('renders preference list after loading', (tester) async {
      final repo = _MockPreferenceRepository(
        results: [
          const PreferenceSummary(
            id: 1,
            name: '测试偏好',
            summary: '2025 · 导数 · 难度 2-8',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: PreferenceListPage(preferenceRepository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('测试偏好'), findsOneWidget);
      await tester.tap(find.byTooltip('选择筛选方案'));
      await tester.pump();
      expect(find.text('已选 1 个'), findsOneWidget);
      expect(find.text('管理方案'), findsOneWidget);
    });
  });
}
