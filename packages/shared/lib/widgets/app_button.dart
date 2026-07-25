import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 章鱼智学统一按钮组件
///
/// 支持类型、全宽、图标、加载态和禁用态。
/// 覆盖 Filled / Elevated / Outlined / Text 四种变体。
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.type = AppButtonType.primary,
    this.variant,
    this.icon,
    this.expanded = true,
    this.fullWidth,
    this.loading = false,
    this.isLoading,
    this.size = AppButtonSize.lg,
    this.minWidth,
  });

  /// 点击回调（null 时自动进入禁用态）
  final VoidCallback? onPressed;

  /// 按钮文本
  final String label;

  /// 变体类型
  final AppButtonType type;

  /// 变体别名（兼容 Phase 1 原命名，覆盖 type）
  final AppButtonVariant? variant;

  /// 前置图标（可选）
  final IconData? icon;

  /// 是否撑满父容器宽度（默认 true）
  final bool expanded;

  /// 全宽别名（兼容 Phase 1 原命名，覆盖 expanded）
  final bool? fullWidth;

  /// 是否显示加载转圈
  final bool loading;

  /// 加载态别名（兼容 Phase 1 原命名，覆盖 loading）
  final bool? isLoading;

  /// 按钮尺寸
  final AppButtonSize size;

  /// 最小宽度（覆盖 expanded 行为时使用）
  final double? minWidth;

  AppButtonType get _effectiveType => variant != null ? AppButtonType.fromVariant(variant!) : type;
  bool get _effectiveExpanded => fullWidth ?? expanded;
  bool get _effectiveLoading => isLoading ?? loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = _effectiveType;
    final disabled = onPressed == null || _effectiveLoading;

    Widget button;
    final content = _buildContent(colors);

    switch (t) {
      case AppButtonType.primary:
        button = FilledButton(
          onPressed: disabled ? null : onPressed,
          style: _primaryStyle(colors),
          child: content,
        );
      case AppButtonType.secondary:
        button = FilledButton(
          onPressed: disabled ? null : onPressed,
          style: _secondaryStyle(colors),
          child: content,
        );
      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: _outlinedStyle(colors),
          child: content,
        );
      case AppButtonType.text:
        button = TextButton(
          onPressed: disabled ? null : onPressed,
          style: _textStyle(colors),
          child: content,
        );
    }

    if (_effectiveExpanded) {
      button = SizedBox(
        width: minWidth ?? double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(AppSemanticColors colors) {
    if (_effectiveLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(colors),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      );
    }

    return Text(label);
  }

  Color _foregroundColor(AppSemanticColors colors) {
    switch (_effectiveType) {
      case AppButtonType.primary:
        return colors.textInverse;
      case AppButtonType.secondary:
        return colors.textPrimary;
      case AppButtonType.outlined:
      case AppButtonType.text:
        return colors.primary;
    }
  }

  ButtonStyle _baseStyle(AppSemanticColors colors) {
    final height = size == AppButtonSize.sm
        ? AppControlSize.sm
        : size == AppButtonSize.md
            ? AppControlSize.md
            : AppControlSize.lg;

    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: size == AppButtonSize.sm ? 12 : 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: size == AppButtonSize.sm ? 13 : 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ButtonStyle _primaryStyle(AppSemanticColors colors) {
    return _baseStyle(colors).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabledBackground;
        if (states.contains(WidgetState.pressed)) return colors.primary.withValues(alpha: 0.85);
        return colors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabledForeground;
        return colors.textInverse;
      }),
    );
  }

  ButtonStyle _secondaryStyle(AppSemanticColors colors) {
    return _baseStyle(colors).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabledBackground;
        if (states.contains(WidgetState.pressed)) return colors.primaryContainer.withValues(alpha: 0.7);
        return colors.primaryContainer;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabledForeground;
        return colors.primaryOnContainer;
      }),
    );
  }

  ButtonStyle _outlinedStyle(AppSemanticColors colors) {
    return _baseStyle(colors).copyWith(
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabledForeground;
        return colors.primary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return BorderSide(color: colors.disabledBackground);
        return BorderSide(color: colors.primaryBorder);
      }),
    );
  }

  ButtonStyle _textStyle(AppSemanticColors colors) {
    return _baseStyle(colors).copyWith(
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabledForeground;
        return colors.primary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return colors.primaryContainer.withValues(alpha: 0.3);
        if (states.contains(WidgetState.pressed)) return colors.primaryContainer.withValues(alpha: 0.5);
        return null;
      }),
    );
  }
}

/// 按钮类型变体
enum AppButtonType {
  /// 主按钮（品牌色填充）
  primary,

  /// 次按钮（浅色容器）
  secondary,

  /// 轮廓按钮
  outlined,

  /// 纯文字按钮
  text;

  static AppButtonType fromVariant(AppButtonVariant v) => switch (v) {
        AppButtonVariant.primary => primary,
        AppButtonVariant.secondary => secondary,
        AppButtonVariant.outlined => outlined,
        AppButtonVariant.text => text,
      };
}

/// 变体别名（原 Phase 1 命名）
enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
}

/// 按钮尺寸
enum AppButtonSize {
  sm,
  md,
  lg,
}
