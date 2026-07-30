class ForegroundSyncPolicy {
  const ForegroundSyncPolicy._();

  static const userCheckInterval = Duration(minutes: 1);
  static const fullCheckInterval = Duration(minutes: 5);
  static const resumeFullCheckInterval = Duration(minutes: 2);
  static const meaningfulBackgroundTime = Duration(seconds: 30);

  static bool shouldCheckAfterResume(Duration backgroundTime) =>
      backgroundTime >= meaningfulBackgroundTime;

  static bool shouldRunFullCheck(DateTime? lastCheck, DateTime now) =>
      lastCheck == null || now.difference(lastCheck) >= resumeFullCheckInterval;

  static bool shouldRunPeriodicFullCheck(DateTime? lastCheck, DateTime now) =>
      lastCheck == null || now.difference(lastCheck) >= fullCheckInterval;
}
