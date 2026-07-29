import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_typography.dart';

void main() {
  test('shared themes use the bundled Noto Sans SC family', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(dark.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(AppTheme.fontFamily, 'packages/shared/NotoSansSC');
  });

  test('shared themes install the app typography scale', () {
    final textTheme = AppTheme.light.textTheme;

    expect(
      textTheme.headlineMedium?.fontSize,
      AppTypography.headlineMedium.fontSize,
    );
    expect(
      textTheme.titleMedium?.fontWeight,
      AppTypography.titleMedium.fontWeight,
    );
    expect(textTheme.bodyMedium?.height, AppTypography.bodyMedium.height);
    expect(textTheme.labelSmall?.fontSize, AppTypography.labelSmall.fontSize);

    for (final style in [
      textTheme.displayLarge,
      textTheme.headlineMedium,
      textTheme.titleMedium,
      textTheme.bodyMedium,
      textTheme.labelSmall,
    ]) {
      expect(style?.fontFamily, AppTheme.fontFamily);
      expect(style?.letterSpacing, 0);
    }
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

  test('component themes keep the bundled font family', () {
    final theme = AppTheme.light;
    final componentStyles = [
      theme.elevatedButtonTheme.style?.textStyle?.resolve({}),
      theme.filledButtonTheme.style?.textStyle?.resolve({}),
      theme.outlinedButtonTheme.style?.textStyle?.resolve({}),
      theme.textButtonTheme.style?.textStyle?.resolve({}),
      theme.chipTheme.labelStyle,
      theme.snackBarTheme.contentTextStyle,
      theme.listTileTheme.titleTextStyle,
      theme.listTileTheme.subtitleTextStyle,
      theme.listTileTheme.leadingAndTrailingTextStyle,
      theme.tooltipTheme.textStyle,
    ];

    for (final style in componentStyles) {
      expect(style?.fontFamily, AppTheme.fontFamily);
    }
  });
}
