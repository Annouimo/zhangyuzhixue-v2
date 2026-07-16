import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shared/theme/app_theme.dart';

/// 渲染 Markdown + LaTeX 数学公式的组件
///
/// 基于 flutter_markdown + flutter_math_fork，支持：
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

    return FlutterMathMarkdown(
      data: data,
      mathTextScaleFactor: fontSize / 14,
      textScaleFactor: fontSize / 14,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: fontSize,
          color: AppColors.textPrimary,
          height: 1.7,
        ),
        h1: TextStyle(
          fontSize: fontSize * 1.3,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        h2: TextStyle(
          fontSize: fontSize * 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        h3: TextStyle(
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        code: TextStyle(
          fontSize: fontSize * 0.9,
          fontFamily: 'monospace',
          color: AppColors.textPrimary,
          backgroundColor: AppColors.background,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
          color: AppColors.background,
        ),
        listBullet: TextStyle(
          fontSize: fontSize,
          color: AppColors.textPrimary,
        ),
      ),
      inlineSyntaxes: [
        md.InlineParser(),
      ],
      blockSyntaxes: [
        md.FencedCodeBlockSyntax(),
      ],
      builders: {
        'math': MathBlockBuilder(),
      },
    );
  }
}
