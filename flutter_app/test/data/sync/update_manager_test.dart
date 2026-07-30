import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/sync/update_manager.dart';

void main() {
  group('UpdateManager.shouldForceUpdate', () {
    test('force flag true returns true', () {
      expect(
        UpdateManager.shouldForceUpdate(
          localVersion: 3,
          serverVersion: 3,
          serverForceUpdate: true,
        ),
        isTrue,
      );
    });

    test('server ahead by 3+ returns true', () {
      expect(
        UpdateManager.shouldForceUpdate(
          localVersion: 1,
          serverVersion: 4,
          serverForceUpdate: false,
        ),
        isTrue,
      );
    });

    test('server ahead by 1 returns false', () {
      expect(
        UpdateManager.shouldForceUpdate(
          localVersion: 3,
          serverVersion: 4,
          serverForceUpdate: false,
        ),
        isFalse,
      );
    });

    test('same version returns false', () {
      expect(
        UpdateManager.shouldForceUpdate(
          localVersion: 3,
          serverVersion: 3,
          serverForceUpdate: false,
        ),
        isFalse,
      );
    });
  });

  group('UpdateManager.shouldShowBanner', () {
    test('server newer shows banner', () {
      expect(
        UpdateManager.shouldShowBanner(localVersion: 2, serverVersion: 3),
        isTrue,
      );
    });

    test('same version hides banner', () {
      expect(
        UpdateManager.shouldShowBanner(localVersion: 3, serverVersion: 3),
        isFalse,
      );
    });

    test('local newer hides banner', () {
      expect(
        UpdateManager.shouldShowBanner(localVersion: 4, serverVersion: 3),
        isFalse,
      );
    });
  });

  group('UpdateSummary download state', () {
    test('complete newer metadata is downloadable', () {
      final summary = UpdateSummary(
        type: 'qbank',
        localVersion: 2,
        serverVersion: 3,
        forceUpdate: false,
        downloadUrl: 'https://example.test/qbank.db.gz',
        checksum: 'abc',
        sizeBytes: 100,
      );

      expect(summary.hasUpdate, isTrue);
      expect(summary.canDownload, isTrue);
      expect(summary.localIsNewer, isFalse);
    });

    test('missing metadata and server downgrade cannot be downloaded', () {
      final incomplete = UpdateSummary(
        type: 'qbank',
        localVersion: 2,
        serverVersion: 3,
        forceUpdate: false,
      );
      final downgrade = UpdateSummary(
        type: 'courses',
        localVersion: 8,
        serverVersion: 4,
        forceUpdate: false,
        downloadUrl: 'https://example.test/courses.db.gz',
        checksum: 'abc',
        sizeBytes: 100,
      );

      expect(incomplete.canDownload, isFalse);
      expect(downgrade.hasUpdate, isFalse);
      expect(downgrade.canDownload, isFalse);
      expect(downgrade.localIsNewer, isTrue);
    });

    test('newer user data can be applied without eager download metadata', () {
      final summary = UpdateSummary(
        type: 'user',
        localVersion: 2,
        serverVersion: 3,
        forceUpdate: false,
      );

      expect(summary.canDownload, isFalse);
      expect(summary.canApply, isTrue);
    });
  });
}
