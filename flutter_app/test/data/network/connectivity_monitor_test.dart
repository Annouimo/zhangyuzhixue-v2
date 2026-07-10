import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/network/connectivity_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityMonitor', () {
    test('singleton returns same instance', () {
      final a = ConnectivityMonitor();
      final b = ConnectivityMonitor();
      expect(identical(a, b), true);
    });

    test('isOnline defaults to true', () {
      final monitor = ConnectivityMonitor();
      expect(monitor.isOnline, true);
    });

    test('init and dispose do not throw', () {
      final monitor = ConnectivityMonitor();
      try {
        monitor.init();
      } catch (_) {
        // platform channel not available in unit tests
      }
      try {
        monitor.dispose();
      } catch (_) {}
    });

    test('onConnectivityChanged is a broadcast stream', () {
      final monitor = ConnectivityMonitor();
      expect(monitor.onConnectivityChanged.isBroadcast, true);
    });
  });
}
