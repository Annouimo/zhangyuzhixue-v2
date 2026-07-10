import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/sync/update_manager.dart';

void main() {
  group('shouldForceUpdate', () {
    test('force flag true returns true', () {
      expect(shouldForceUpdate(localVersion: 3, serverVersion: 3, serverForceUpdate: true), isTrue);
    });

    test('server ahead by 3+ returns true', () {
      expect(shouldForceUpdate(localVersion: 1, serverVersion: 4, serverForceUpdate: false), isTrue);
    });

    test('server ahead by 1 returns false', () {
      expect(shouldForceUpdate(localVersion: 3, serverVersion: 4, serverForceUpdate: false), isFalse);
    });

    test('same version returns false', () {
      expect(shouldForceUpdate(localVersion: 3, serverVersion: 3, serverForceUpdate: false), isFalse);
    });
  });

  group('shouldShowBanner', () {
    test('server newer shows banner', () {
      expect(shouldShowBanner(localVersion: 2, serverVersion: 3), isTrue);
    });

    test('same version hides banner', () {
      expect(shouldShowBanner(localVersion: 3, serverVersion: 3), isFalse);
    });

    test('local newer hides banner', () {
      expect(shouldShowBanner(localVersion: 4, serverVersion: 3), isFalse);
    });
  });
}
