import 'package:flutter/material.dart';

/// 章鱼智学设计系统颜色常量
/// 参考：docs/04-UI/设计系统.md
abstract final class AppColors {
  static const primary = Color(0xFF4A6CF7);
  static const primaryLight = Color(0xFFEEF1FF);
  static const background = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const border = Color(0xFFE5E7EB);
}

/// 间距与圆角常量
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

  /// 根据分段标准取段名
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

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamilyFallback: _fontFamilyFallback,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
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
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}
