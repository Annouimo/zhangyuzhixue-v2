import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../app_theme.dart';

/// 渲染 Markdown + LaTeX 数学公式的组件
///
/// 基于 flutter_markdown，支持：
/// - Markdown 语法（粗体、列表、标题等）
/// - LaTeX 数学公式（$$...$$ 行间、$...$ 行内）
/// - 自定义样式匹配设计系统
class MdLatexBody extends StatelessWidget {
  final String data;
  final double fontSize;

  const MdLatexBody(
    this.data, {
    super.key,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: fontSize,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        h1: TextStyle(
          fontSize: fontSize + 6,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        h2: TextStyle(
          fontSize: fontSize + 4,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.normal,
          color: AppColors.textSecondary,
        ),
        code: TextStyle(
          fontSize: fontSize - 1,
          backgroundColor: Colors.grey[100],
          color: AppColors.textPrimary,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(4),
        ),
        listBullet: TextStyle(
          fontSize: fontSize,
          color: AppColors.textSecondary,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
      ),
    );
  }
}
