import 'package:flutter/material.dart';

/// 品牌色 — 来自已定稿 App 图标（不与交互色共享）
abstract final class BrandColors {
  static const blueBright = Color(0xFF1D8EFE);
  static const blue = Color(0xFF1488F7);
  static const blueDeep = Color(0xFF0A80FE);
  static const sky = Color(0xFF73BAF9);
  static const ice = Color(0xFFCEE8FD);
  static const white = Color(0xFFFFFFFF);

  /// 品牌渐变色阶（135deg）
  static const gradient = [blueBright, blue, blueDeep];
}

/// 章鱼智学 V1.0 色彩系统 — 浅色模式
/// 命名与设计规范 V1.0 附录 A 一致
abstract final class AppColors {
  // ── 主交互色 ──
  static const primary = Color(0xFF006BD1);
  static const primaryHover = Color(0xFF0062C4);
  static const primaryPressed = Color(0xFF0055AA);
  static const primaryContainer = Color(0xFFEAF4FF);
  static const primaryOnContainer = Color(0xFF0055AA);
  static const primaryBorder = Color(0xFF9FCEFF);

  // ── 页面与表层 ──
  static const background = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF0F4F8);
  static const surfaceRaised = Color(0xFFFFFFFF);

  // ── 文字层级 ──
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF536274);
  static const textMuted = Color(0xFF667589);
  static const textInverse = Color(0xFFFFFFFF);

  // ── 边框与分割线 ──
  static const border = Color(0xFFDEE5ED);
  static const borderStrong = Color(0xFF7B8A9D);
  static const divider = Color(0xFFE8EDF3);

  // ── 禁用态 ──
  static const disabledBackground = Color(0xFFE9EEF4);
  static const disabledForeground = Color(0xFF667589);

  // ── 语义色 — 主色 ──
  static const success = Color(0xFF087A55);
  static const warning = Color(0xFFF5A524);
  static const error = Color(0xFFD92D20);
  static const info = Color(0xFF006BD1);
  static const recommendation = Color(0xFFE59A00);

  // ── 语义色 — 容器 ──
  static const successContainer = Color(0xFFE8F7F0);
  static const onSuccessContainer = Color(0xFF065F46);
  static const warningContainer = Color(0xFFFFF3D6);
  static const onWarningContainer = Color(0xFF6B3A00);
  static const errorContainer = Color(0xFFFFF0EF);
  static const onErrorContainer = Color(0xFF9F1B15);
  static const infoContainer = Color(0xFFEAF4FF);
  static const onInfoContainer = Color(0xFF0055AA);
  static const recommendationContainer = Color(0xFFFFF4D6);
  static const onRecommendationContainer = Color(0xFF7A4500);

  // ── 辅助 ──
  static const scrim = Color(0xCC081220); // rgba(8,18,32,.56) → 0xCC
  static const focusRing = Color(0xFF5CAEFF);
  static const selectionBackground = Color(0xFFCDE5FF);
  static const selectionText = Color(0xFF0B2D50);
  static const mediaSurface = Color(0xFFFFFFFF);
  static const imageBorder = Color(0xFFC8D2DE);

  // ── 旧令牌兼容别名（指向新值） ──
  static const primaryLight = primaryContainer;
  static const card = surface;
  static const tagDifficultyBg = warningContainer;
  static const tagDifficultyFg = onWarningContainer;
  static const statusCompletedBg = successContainer;
  static const statusInProgressBg = infoContainer;
  static const statusPendingBg = surfaceSubtle;
  static const heatmapLevel1 = Color(0xFFEAF4FF);
  static const heatmapLevel2 = Color(0xFF7CC0FF);
  static const heatmapLevel3 = primary;
}

/// 章鱼智学 V1.0 色彩系统 — 深色模式
abstract final class AppColorsDark {
  static const primary = Color(0xFF5CAEFF);
  static const primaryHover = Color(0xFF85C3FF);
  static const primaryPressed = Color(0xFF3F9CF0);
  static const primaryContainer = Color(0xFF12365B);
  static const primaryOnContainer = Color(0xFFCDE6FF);
  static const primaryBorder = Color(0xFF3F7DB8);

  static const background = Color(0xFF0B1220);
  static const surface = Color(0xFF111C2D);
  static const surfaceSubtle = Color(0xFF162235);
  static const surfaceRaised = Color(0xFF1B2A40);

  static const textPrimary = Color(0xFFF4F7FB);
  static const textSecondary = Color(0xFFB9C2CF);
  static const textMuted = Color(0xFF8994A5);
  static const textInverse = Color(0xFF172033);

  static const border = Color(0xFF2A3A50);
  static const borderStrong = Color(0xFF5C6D82);
  static const divider = Color(0xFF223146);

  static const disabledBackground = Color(0xFF222E3E);
  static const disabledForeground = Color(0xFF8994A5);

  static const success = Color(0xFF67D6AD);
  static const warning = Color(0xFFFFD37A);
  static const error = Color(0xFFFF8B84);
  static const info = Color(0xFF85C3FF);
  static const recommendation = Color(0xFFFFC65A);

  static const successContainer = Color(0xFF123B31);
  static const onSuccessContainer = Color(0xFFA7EACF);
  static const warningContainer = Color(0xFF49350F);
  static const onWarningContainer = Color(0xFFFFE2A5);
  static const errorContainer = Color(0xFF4A1D1D);
  static const onErrorContainer = Color(0xFFFFC1BD);
  static const infoContainer = Color(0xFF12365B);
  static const onInfoContainer = Color(0xFFCDE6FF);
  static const recommendationContainer = Color(0xFF4A3510);
  static const onRecommendationContainer = Color(0xFFFFE1A1);

  static const scrim = Color(0xA3000000); // rgba(0,0,0,.64) → 0xA3
  static const focusRing = Color(0xFF85C3FF);
  static const selectionBackground = Color(0xFF123D68);
  static const selectionText = Color(0xFFEAF4FF);
  static const mediaSurface = Color(0xFFFFFFFF);
  static const imageBorder = Color(0xFF5C6D82);
}

/// ThemeExtension — 产品语义色（通过 Theme.of 运行时读取）
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.primary,
    required this.primaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.disabledBackground,
    required this.disabledForeground,
    required this.focusRing,
    required this.scrim,
    required this.mediaSurface,
    required this.imageBorder,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.recommendation,
    required this.successContainer,
    required this.warningContainer,
    required this.errorContainer,
    required this.infoContainer,
    required this.recommendationContainer,
    required this.onSuccessContainer,
    required this.onWarningContainer,
    required this.onErrorContainer,
    required this.onInfoContainer,
    required this.onRecommendationContainer,
  });

  final Color primary;
  final Color primaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color disabledBackground;
  final Color disabledForeground;
  final Color focusRing;
  final Color scrim;
  final Color mediaSurface;
  final Color imageBorder;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color recommendation;
  final Color successContainer;
  final Color warningContainer;
  final Color errorContainer;
  final Color infoContainer;
  final Color recommendationContainer;
  final Color onSuccessContainer;
  final Color onWarningContainer;
  final Color onErrorContainer;
  final Color onInfoContainer;
  final Color onRecommendationContainer;

  static const light = AppSemanticColors(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceSubtle: AppColors.surfaceSubtle,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    divider: AppColors.divider,
    disabledBackground: AppColors.disabledBackground,
    disabledForeground: AppColors.disabledForeground,
    focusRing: AppColors.focusRing,
    scrim: AppColors.scrim,
    mediaSurface: AppColors.mediaSurface,
    imageBorder: AppColors.imageBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    recommendation: AppColors.recommendation,
    successContainer: AppColors.successContainer,
    warningContainer: AppColors.warningContainer,
    errorContainer: AppColors.errorContainer,
    infoContainer: AppColors.infoContainer,
    recommendationContainer: AppColors.recommendationContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    onWarningContainer: AppColors.onWarningContainer,
    onErrorContainer: AppColors.onErrorContainer,
    onInfoContainer: AppColors.onInfoContainer,
    onRecommendationContainer: AppColors.onRecommendationContainer,
  );

  static const dark = AppSemanticColors(
    primary: AppColorsDark.primary,
    primaryContainer: AppColorsDark.primaryContainer,
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceSubtle: AppColorsDark.surfaceSubtle,
    textPrimary: AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    textMuted: AppColorsDark.textMuted,
    border: AppColorsDark.border,
    borderStrong: AppColorsDark.borderStrong,
    divider: AppColorsDark.divider,
    disabledBackground: AppColorsDark.disabledBackground,
    disabledForeground: AppColorsDark.disabledForeground,
    focusRing: AppColorsDark.focusRing,
    scrim: AppColorsDark.scrim,
    mediaSurface: AppColorsDark.mediaSurface,
    imageBorder: AppColorsDark.imageBorder,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    error: AppColorsDark.error,
    info: AppColorsDark.info,
    recommendation: AppColorsDark.recommendation,
    successContainer: AppColorsDark.successContainer,
    warningContainer: AppColorsDark.warningContainer,
    errorContainer: AppColorsDark.errorContainer,
    infoContainer: AppColorsDark.infoContainer,
    recommendationContainer: AppColorsDark.recommendationContainer,
    onSuccessContainer: AppColorsDark.onSuccessContainer,
    onWarningContainer: AppColorsDark.onWarningContainer,
    onErrorContainer: AppColorsDark.onErrorContainer,
    onInfoContainer: AppColorsDark.onInfoContainer,
    onRecommendationContainer: AppColorsDark.onRecommendationContainer,
  );

  @override
  AppSemanticColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? disabledBackground,
    Color? disabledForeground,
    Color? focusRing,
    Color? scrim,
    Color? mediaSurface,
    Color? imageBorder,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? recommendation,
    Color? successContainer,
    Color? warningContainer,
    Color? errorContainer,
    Color? infoContainer,
    Color? recommendationContainer,
    Color? onSuccessContainer,
    Color? onWarningContainer,
    Color? onErrorContainer,
    Color? onInfoContainer,
    Color? onRecommendationContainer,
  }) {
    return AppSemanticColors(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      focusRing: focusRing ?? this.focusRing,
      scrim: scrim ?? this.scrim,
      mediaSurface: mediaSurface ?? this.mediaSurface,
      imageBorder: imageBorder ?? this.imageBorder,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      recommendation: recommendation ?? this.recommendation,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      errorContainer: errorContainer ?? this.errorContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      recommendationContainer: recommendationContainer ?? this.recommendationContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      onRecommendationContainer: onRecommendationContainer ?? this.onRecommendationContainer,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors other, double t) {
    return AppSemanticColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabledBackground: Color.lerp(disabledBackground, other.disabledBackground, t)!,
      disabledForeground: Color.lerp(disabledForeground, other.disabledForeground, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      mediaSurface: Color.lerp(mediaSurface, other.mediaSurface, t)!,
      imageBorder: Color.lerp(imageBorder, other.imageBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      recommendation: Color.lerp(recommendation, other.recommendation, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      recommendationContainer: Color.lerp(recommendationContainer, other.recommendationContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      onRecommendationContainer: Color.lerp(onRecommendationContainer, other.onRecommendationContainer, t)!,
    );
  }
}

/// 布局尺寸常量
abstract final class AppSizes {
  static const double baseSpacing = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double maxContentWidth = 480.0;
}

/// 题型中文映射
abstract final class QuestionTypeLabels {
  static const Map<String, String> labels = {
    'choice': '选择题',
    'fill': '填空题',
    'solution': '解答题',
  };

  static String of(String type) => labels[type] ?? type;
}

/// 难度分段（0~10）常量
abstract final class DifficultySegments {
  static const List<double> diffBreaks = [0.0, 3.0, 5.0, 7.0, 8.5, 10.0];
  static const List<String> diffLabels = ['基础', '中档', '中难', '较难', '压轴'];
  static const List<double> calcBreaks = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0];
  static const List<String> calcLabels = ['少量', '较少', '适中', '较多', '繁琐'];

  static String nameFor(double value, {required List<double> breaks, required List<String> labels}) {
    final idx = breaks.lastIndexWhere((b) => value >= b);
    return labels[idx.clamp(0, labels.length - 1)];
  }

  static String diffNameFor(double value) => nameFor(value, breaks: diffBreaks, labels: diffLabels);
  static String calcNameFor(double value) => nameFor(value, breaks: calcBreaks, labels: calcLabels);
}

/// 应用主题
class AppTheme {
  static const _fontFamilyFallback = [
    'Microsoft YaHei',
    'PingFang SC',
    'Noto Sans CJK SC',
  ];

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        colors: AppSemanticColors.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textInverse,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.primaryOnContainer,
          secondary: AppColors.info,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: AppColors.textInverse,
          outline: AppColors.border,
          outlineVariant: AppColors.divider,
        ),
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        colors: AppSemanticColors.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColorsDark.primary,
          onPrimary: AppColorsDark.textInverse,
          primaryContainer: AppColorsDark.primaryContainer,
          onPrimaryContainer: AppColorsDark.primaryOnContainer,
          secondary: AppColorsDark.info,
          surface: AppColorsDark.surface,
          onSurface: AppColorsDark.textPrimary,
          error: AppColorsDark.error,
          onError: AppColorsDark.textInverse,
          outline: AppColorsDark.border,
          outlineVariant: AppColorsDark.divider,
        ),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppSemanticColors colors,
    required ColorScheme colorScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamilyFallback: _fontFamilyFallback,
      colorScheme: colorScheme,
      extensions: [colors],
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: brightness == Brightness.light
              ? AppColors.textInverse
              : AppColorsDark.textInverse,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          borderSide: BorderSide(color: colors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      disabledColor: colors.disabledForeground,
    );
  }
}

/// BuildContext 快捷取色
extension ThemeColors on BuildContext {
  AppSemanticColors get colors => Theme.of(this).extension<AppSemanticColors>()!;
}
