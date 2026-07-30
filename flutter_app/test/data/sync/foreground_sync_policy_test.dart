import 'package:flutter_app/data/sync/foreground_sync_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foreground polling intervals match the sync policy', () {
    expect(ForegroundSyncPolicy.userCheckInterval, const Duration(minutes: 1));
    expect(ForegroundSyncPolicy.fullCheckInterval, const Duration(minutes: 5));
  });

  test('resume checks start after thirty seconds in background', () {
    expect(
      ForegroundSyncPolicy.shouldCheckAfterResume(const Duration(seconds: 29)),
      isFalse,
    );
    expect(
      ForegroundSyncPolicy.shouldCheckAfterResume(const Duration(seconds: 30)),
      isTrue,
    );
  });

  test('full resume check uses a two minute cooldown', () {
    final now = DateTime(2026, 7, 31, 10);
    expect(ForegroundSyncPolicy.shouldRunFullCheck(null, now), isTrue);
    expect(
      ForegroundSyncPolicy.shouldRunFullCheck(
        now.subtract(const Duration(minutes: 1, seconds: 59)),
        now,
      ),
      isFalse,
    );
    expect(
      ForegroundSyncPolicy.shouldRunFullCheck(
        now.subtract(const Duration(minutes: 2)),
        now,
      ),
      isTrue,
    );
  });

  test('periodic full check replaces the user check every five minutes', () {
    final now = DateTime(2026, 7, 31, 10);
    expect(
      ForegroundSyncPolicy.shouldRunPeriodicFullCheck(
        now.subtract(const Duration(minutes: 4, seconds: 59)),
        now,
      ),
      isFalse,
    );
    expect(
      ForegroundSyncPolicy.shouldRunPeriodicFullCheck(
        now.subtract(const Duration(minutes: 5)),
        now,
      ),
      isTrue,
    );
  });
}
