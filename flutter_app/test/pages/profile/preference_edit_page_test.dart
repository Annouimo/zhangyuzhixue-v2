import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/pages/profile/preference_edit_page.dart';
import '../../test_setup.dart';

class _MockPreferenceRepository implements PreferenceRepository {
  @override
  Future<List<PreferenceSummary>> getList() async => [];

  @override
  Future<void> delete(int id) async {}

  @override
  Future<int> getCount() async => 0;

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
    setUp(() => setupTestHooks());
  group('PreferenceEditPage', () {
    testWidgets('renders create mode with name field and save button',
        (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceEditPage(preferenceRepository: repo),
        ),
      );
      expect(find.text('新建偏好'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('shows no loading indicator in create mode', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceEditPage(preferenceRepository: repo),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders filter settings card', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: PreferenceEditPage(preferenceRepository: repo),
        ),
      );
      expect(find.text('筛选条件'), findsOneWidget);
      expect(find.text('按来源筛选'), findsOneWidget);
      expect(find.text('按概念标签筛选'), findsOneWidget);
      expect(find.text('按难度/计算量筛选'), findsOneWidget);
    });
  });
}
