import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/debug/audit_logger.dart';

/// 题库配图组件 — 使用 AssetImage 加载，符合图片路由规范
class QuestionImage extends StatelessWidget {
  final String relativePath;
  final double? width;
  final double? maxHeight;
  final BoxFit fit;

  const QuestionImage({
    super.key,
    required this.relativePath,
    this.width,
    this.maxHeight,
    this.fit = BoxFit.contain,
  });

  static const String _assetBase = 'assets/questions/images';

  String get _assetPath => '$_assetBase/$relativePath';

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    final audit = AuditLogger.instance;
    final effectiveWidth = width ?? double.infinity;
    final effectiveMaxHeight = maxHeight ?? MediaQuery.of(context).size.height * 0.4;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          _assetPath,
          width: effectiveWidth,
          height: effectiveMaxHeight,
          fit: fit,
          errorBuilder: (_, error, _) {
            audit.error('QuestionImage', '$error ($_assetPath)');
            return _buildPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
      final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 28, color: colors.textSecondary),
              SizedBox(height: 4),
              Text('配图加载失败',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
