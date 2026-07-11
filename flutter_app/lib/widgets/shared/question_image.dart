import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 题库配图组件 — 使用 AssetImage 加载，符合图片路由规范
///
/// 配图路径规范：`QuestionDetail.images` 存储相对路径如 `一模/2024/海淀/q17.webp`
/// 解析规则：拼接 `assets/questions/images/` 前缀后通过 AssetImage 加载
/// 三态覆盖：正常显示 → 加载失败显示占位图标
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          _assetPath,
          width: width,
          height: maxHeight,
          fit: fit,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 28, color: AppColors.textSecondary),
              SizedBox(height: 4),
              Text('配图加载失败',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
