import 'package:flutter/material.dart';

/// 章鱼智学 V1.0 间距令牌
///
/// 使用 4px 基准网格，覆盖 UI 中所有固定间距场景。
/// 业务页面中的间距应从这里读取，不出现任意数值。
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 章鱼智学 V1.0 圆角令牌
abstract final class AppRadius {
  static const double none = 0;
  static const double sm = 4;
  static const double small = 4;
  static const double md = 8;
  static const double medium = 8;
  static const double lg = 12;
  static const double large = 12;
  static const double xl = 16;
  static const double extraLarge = 16;
  static const double full = 999;
  static const double pill = 999;
}

/// 章鱼智学 V1.0 控件尺寸
abstract final class AppControlSize {
  static const double xs = 24;
  static const double sm = 32;
  static const double md = 40;
  static const double lg = 48;
  static const double xl = 56;
}

/// 章鱼智学 V1.0 断点（基于 Material 3 规范）
abstract final class AppBreakpoints {
  /// 紧凑布局 < 600dp — 手机竖屏
  static const double compact = 0;

  /// 中等布局 >= 600dp — 平板竖屏 / 手机横屏
  static const double medium = 600;

  /// 宽屏布局 >= 840dp — 平板横屏 / 桌面
  static const double expanded = 840;

  /// 超大屏 >= 1200dp — 桌面宽屏
  static const double large = 1200;
}

/// 章鱼智学 V1.0 内容区域最大宽度
///
/// 使宽屏下内容不随窗口无限制拉伸，保持可读性。
abstract final class AppContentWidth {
  /// 表单类页面（登录、注册、设置）
  static const double form = 440;

  /// 阅读类页面（讲义、解析）
  static const double reading = 680;

  /// 标准内容区（列表、详情）
  static const double standard = 840;

  /// 仪表盘/概览页面（首页、统计）
  static const double dashboard = 1080;

  /// 做题区域
  static const double solving = 960;
}

/// 章鱼智学 V1.0 动效令牌
abstract final class AppMotion {
  // ── 时长 ──
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // ── 曲线 ──
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.fastOutSlowIn;
  static const Curve emphasizedCurve = Curves.fastOutSlowIn;
  static const Curve decelerate = Curves.decelerate;
}

/// 章鱼智学 V1.0 阴影令牌 — 浅色模式
abstract final class AppShadows {
  static List<BoxShadow> get level1 => [
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ];

  static List<BoxShadow> get level2 => [
        BoxShadow(
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: -1,
          color: Colors.black.withValues(alpha: 0.10),
        ),
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ];

  static List<BoxShadow> get level3 => [
        BoxShadow(
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
          color: Colors.black.withValues(alpha: 0.12),
        ),
        BoxShadow(
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ];
}
