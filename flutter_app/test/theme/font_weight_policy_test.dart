import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI source only requests bundled font weights', () {
    final roots = [Directory('lib'), Directory('../packages/shared/lib')];
    final forbidden = RegExp(r'FontWeight\.(w500|w700|bold|normal)');
    final violations = <String>[];

    for (final root in roots) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final match in forbidden.allMatches(entity.readAsStringSync())) {
          violations.add('${entity.path}: ${match.group(0)}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
