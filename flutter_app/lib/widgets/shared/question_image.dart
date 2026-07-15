import 'package:flutter/material.dart';
import 'dart:io';
import '../../app_theme.dart';
import '../../data/database/database_provider.dart';

/// 题库配图组件 — 从 documents/images/ 加载（Image.file）或回退到 asset bundle
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

  String get _assetPath => 'assets/questions/images/$relativePath';

  @override
  Widget build(BuildContext context) {
    final imagesDir = DatabaseProvider().imagesDir;
    final filePath = '$imagesDir/$relativePath';
    final file = File(filePath);
    final effectiveWidth = width ?? double.infinity;
    final effectiveMaxHeight = maxHeight ?? MediaQuery.of(context).size.height * 0.4;

    Widget image;
    if (file.existsSync()) {
      image = Image.file(
        file,
        width: effectiveWidth,
        height: effectiveMaxHeight,
        fit: fit,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      image = Image.asset(
        _assetPath,
        width: effectiveWidth,
        height: effectiveMaxHeight,
        fit: fit,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.border,
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
