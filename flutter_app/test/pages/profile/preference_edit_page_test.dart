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
  group('PreferenceEditPage', () {
    testWidgets('renders create mode with name field and save button', (
      tester,
    ) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(home: PreferenceEditPage(preferenceRepository: repo)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('新建范围'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('创建范围'), findsOneWidget);
    });

    testWidgets('shows no loading indicator in create mode', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(home: PreferenceEditPage(preferenceRepository: repo)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders filter settings card', (tester) async {
      final repo = _MockPreferenceRepository();
      await tester.pumpWidget(
        MaterialApp(home: PreferenceEditPage(preferenceRepository: repo)),
      );
      // Wait for async option loading to complete (will fail gracefully)
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('方案名称'), findsOneWidget);
      expect(find.text('试题来源'), findsOneWidget);
      expect(find.text('创建范围'), findsOneWidget);
    });
  });
}
