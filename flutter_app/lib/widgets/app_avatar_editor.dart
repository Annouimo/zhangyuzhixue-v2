import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// 统一的头像展示、上传状态和编辑入口。
class AppAvatarEditor extends StatelessWidget {
  const AppAvatarEditor({
    super.key,
    required this.onPressed,
    this.imageProvider,
    this.fallback,
    this.uploading = false,
    this.radius = 40,
    this.semanticLabel = '更换头像',
  });

  final VoidCallback? onPressed;
  final ImageProvider<Object>? imageProvider;
  final Widget? fallback;
  final bool uploading;
  final double radius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null && !uploading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: radius,
                    backgroundColor: colors.primaryContainer,
                    backgroundImage: imageProvider,
                    child: imageProvider == null ? fallback : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 3),
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: uploading
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                                color: colors.onPrimary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
