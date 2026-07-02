import 'package:flutter/material.dart';

/// 章鱼智学全局主题常量
class AppTheme {
  // 颜色
  static const Color primaryColor = Color(0xFF1565C0);       // 主色蓝
  static const Color primaryLight = Color(0xFF5E92F3);       // 浅蓝
  static const Color primaryDark = Color(0xFF003C8F);        // 深蓝
  static const Color accentColor = Color(0xFFFF6F00);        // 强调橙
  static const Color bgColor = Color(0xFFF5F5F5);            // 背景灰
  static const Color cardColor = Colors.white;                // 卡片白
  static const Color textPrimary = Color(0xFF212121);        // 主文字
  static const Color textSecondary = Color(0xFF757575);      // 副文字
  static const Color dividerColor = Color(0xFFE0E0E0);       // 分割线
  static const Color statusGreen = Color(0xFF4CAF50);        // 已完成绿
  static const Color statusOrange = Color(0xFFFF9800);       // 进行中橙
  static const Color statusGray = Color(0xFF9E9E9E);         // 未做灰

  // 间距
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // 圆角
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;

  // 字体大小
  static const double fontSizeSmall = 13.0;
  static const double fontSizeBody = 15.0;
  static const double fontSizeTitle = 17.0;
  static const double fontSizeLarge = 20.0;

  // 阴影
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(20),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
