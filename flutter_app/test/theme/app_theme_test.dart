import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/theme/app_theme.dart';

void main() {
  test('shared themes use the bundled Noto Sans SC family', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(dark.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(AppTheme.fontFamily, 'packages/shared/NotoSansSC');
  });

  test('navigation labels derive from the shared text theme', () {
    final theme = AppTheme.light;
    final navigationBarLabels = theme.navigationBarTheme.labelTextStyle;

    expect(
      theme.navigationRailTheme.selectedLabelTextStyle?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(
      theme.navigationRailTheme.unselectedLabelTextStyle?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(
      navigationBarLabels?.resolve({WidgetState.selected})?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(navigationBarLabels?.resolve({})?.fontFamily, AppTheme.fontFamily);
  });
}
