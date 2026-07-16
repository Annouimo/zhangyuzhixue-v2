import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';

void main() {
  group('AppPrefs', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPrefs().init();
    });

    test('accessToken read/write', () async {
      expect(AppPrefs().accessToken, isNull);
      await AppPrefs().setAccessToken('token123');
      expect(AppPrefs().accessToken, 'token123');
    });

    test('refreshToken read/write', () async {
      await AppPrefs().setRefreshToken('refresh456');
      expect(AppPrefs().refreshToken, 'refresh456');
    });

    test('qbankVersion defaults to 0', () async {
      expect(AppPrefs().qbankVersion, 0);
    });

    test('qbankVersion read/write', () async {
      await AppPrefs().setQbankVersion(5);
      expect(AppPrefs().qbankVersion, 5);
    });

    test('coursesVersion read/write', () async {
      await AppPrefs().setCoursesVersion(3);
      expect(AppPrefs().coursesVersion, 3);
    });

    test('accessibleCourseIds defaults to empty', () async {
      expect(AppPrefs().accessibleCourseIds, isEmpty);
    });

    test('accessibleCourseIds read/write', () async {
      await AppPrefs().setAccessibleCourseIds([1, 2, 3]);
      expect(AppPrefs().accessibleCourseIds, [1, 2, 3]);
    });

    test('clearAll clears everything', () async {
      await AppPrefs().setAccessToken('tok');
      await AppPrefs().setQbankVersion(5);
      await AppPrefs().clearAll();
      expect(AppPrefs().accessToken, isNull);
      expect(AppPrefs().qbankVersion, 0);
    });

    test('hasKey returns correct result', () async {
      expect(AppPrefs().hasKey(PrefKeys.accessToken), false);
      await AppPrefs().setAccessToken('x');
      expect(AppPrefs().hasKey(PrefKeys.accessToken), true);
    });

    test('getInt with defaultValue', () async {
      expect(AppPrefs().getInt('nonexistent'), 0);
      await AppPrefs().setQbankVersion(7);
      expect(AppPrefs().getInt(PrefKeys.qbankVersion), 7);
    });

    test('lastUpdatePromptTimestamp read/write', () async {
      await AppPrefs().setLastUpdatePromptTimestamp(100);
      expect(AppPrefs().lastUpdatePromptTimestamp, 100);
    });

    test('singleton returns same instance', () async {
      final a = AppPrefs();
      final b = AppPrefs();
      expect(identical(a, b), true);
    });

    group('ratingCooldown', () {
      test('isRatingCooldownActive returns false when never set', () {
        expect(AppPrefs().isRatingCooldownActive('solve_42'), false);
      });

      test('setRatingCooldown and isRatingCooldownActive', () async {
        await AppPrefs().setRatingCooldown('solve_42');
        expect(AppPrefs().isRatingCooldownActive('solve_42'), true);
      });

      test('cooldown is per page URL', () async {
        await AppPrefs().setRatingCooldown('page_a');
        expect(AppPrefs().isRatingCooldownActive('page_a'), true);
        expect(AppPrefs().isRatingCooldownActive('page_b'), false);
      });
    });
  });
}
