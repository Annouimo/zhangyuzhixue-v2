import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_icons.dart';
import 'app_card.dart';

/// 登录、注册等认证页面的统一品牌布局。
class AppAuthLayout extends StatelessWidget {
  const AppAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.leading,
    this.logoAsset = 'assets/logo_mark.png',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? leading;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.background, colors.surface],
            stops: const [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final expanded = constraints.maxWidth >= AppBreakpoints.medium;
              final form = AppCard(
                elevated: true,
                padding: EdgeInsets.all(expanded ? AppSpacing.xl : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (leading != null) ...[
                      Align(alignment: Alignment.centerLeft, child: leading!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(title, style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    child,
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      footer!,
                    ],
                  ],
                ),
              );

              return SingleChildScrollView(
                padding: EdgeInsets.all(expanded ? AppSpacing.xl : AppSpacing.md),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        (expanded ? AppSpacing.xl * 2 : AppSpacing.md * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: expanded
                          ? Row(
                              children: [
                                Expanded(child: _BrandPanel(logoAsset: logoAsset)),
                                const SizedBox(width: AppSpacing.xl),
                                SizedBox(width: AppContentWidth.form, child: form),
                              ],
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppContentWidth.form,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CompactBrand(logoAsset: logoAsset),
                                  const SizedBox(height: AppSpacing.lg),
                                  form,
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandMark(logoAsset: logoAsset, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text('章鱼智学', style: textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '让每一次练习都有明确目标，\n让每一步进步都看得见。',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _BrandPoint(icon: Icons.auto_awesome_outlined, label: '个性化推荐'),
              _BrandPoint(icon: Icons.insights_outlined, label: '学习进度追踪'),
              _BrandPoint(icon: Icons.school_outlined, label: '高考数学专项'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BrandMark(logoAsset: logoAsset, size: 44),
        const SizedBox(width: AppSpacing.sm),
        Text('章鱼智学', style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.logoAsset, required this.size});

  final String logoAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: BrandColors.gradient,
        ),
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? AppShadows.medium
            : const [],
      ),
      child: Image.asset(logoAsset, fit: BoxFit.contain),
    );
  }
}

class _BrandPoint extends StatelessWidget {
  const _BrandPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}