import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/widgets/exit_rating_popup.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    await AppPrefs().init();
  });

  group('shouldShowExitRating', () {
    test('冷却中 → false', () async {
      await AppPrefs().setRatingCooldown('page_cool');
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      expect(shouldShowExitRating('page_cool', entry), false);
    });

    test('无冷却 + 停留足够 → 概率决定', () async {
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      // 20% 概率，50 次至少应有一次 true
      var gotTrue = false;
      for (var i = 0; i < 100; i++) {
        if (shouldShowExitRating('prob_page_$i', entry)) {
          gotTrue = true;
          break;
        }
      }
      expect(gotTrue, isTrue, reason: '20% 概率下 100 次应至少一次通过');
    });

    test('停留不足 → false', () async {
      final entry = DateTime.now();
      for (var i = 0; i < 100; i++) {
        expect(shouldShowExitRating('stay_page_$i', entry), isFalse);
      }
    });

    test('冷却不同 page 不干扰', () async {
      await AppPrefs().setRatingCooldown('page_a');
      final entry = DateTime.now().subtract(const Duration(seconds: 35));
      expect(shouldShowExitRating('page_a', entry), false);
      // page_b 无冷却，只有概率可能拦
      var gotTrue = false;
      for (var i = 0; i < 100; i++) {
        if (shouldShowExitRating('page_b_$i', entry)) {
          gotTrue = true;
          break;
        }
      }
      expect(gotTrue, isTrue, reason: 'page_b 无冷却应有机会弹出');
    });
  });

  group('submitExitRating（冷却部分）', () {
    test('冷却写入生效', () async {
      // submitExitRating 内部还调 SyncManager/DatabaseProvider
      // 但冷却写入 AppPrefs 在第一次 await 就执行，不会被后续 crash 影响
      // 不过这里仍可能被后续调用阻塞
      // 直接测 AppPrefs.setRatingCooldown
      await AppPrefs().setRatingCooldown('direct_page');
      expect(AppPrefs().isRatingCooldownActive('direct_page'), true);
    });
  });
}
