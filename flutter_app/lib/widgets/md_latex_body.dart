import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../../app_theme.dart';

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

    return MarkdownBody(
      data: data,
      selectable: true,
      blockSyntaxes: [_BlockMathSyntax()],
      inlineSyntaxes: [_InlineLatexSyntax()],
      builders: {
        'latex_inline': _InlineLatexBuilder(),
        'math_block': _BlockMathBuilder(),
      },
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

// ─── 行内公式 $...$ ───

class _InlineLatexSyntax extends md.InlineSyntax {
  _InlineLatexSyntax() : super(r'\$([^$]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('latex_inline', match[1]!));
    return true;
  }
}

class _InlineLatexBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return _SafeMath(
      tex: element.textContent,
      mathStyle: MathStyle.text,
      textStyle: TextStyle(
        fontSize: preferredStyle?.fontSize ?? 14,
        color: preferredStyle?.color,
      ),
    );
  }
}

// ─── 块级公式 $$...$$ ───

class _BlockMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$');

  @override
  bool canEndBlock(md.BlockParser parser) => true;

  @override
  md.Node parse(md.BlockParser parser) {
    final line = parser.current.content;

    // 单行: $$a^2 + b^2 = c^2$$
    final single = RegExp(r'^\$\$(.*)\$\$$').firstMatch(line);
    if (single != null) {
      parser.advance();
      return md.Element.text('math_block', single[1]!.trim());
    }

    // 多行: $$\n...\n$$
    final buf = StringBuffer();
    parser.advance();
    while (!parser.isDone) {
      final cur = parser.current;
      if (cur.content.trim() == r'$$') {
        parser.advance();
        break;
      }
      buf.writeln(cur.content);
      parser.advance();
    }
    return md.Element.text('math_block', buf.toString().trimRight());
  }
}

class _BlockMathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return _SafeMath(
      tex: element.textContent,
      mathStyle: MathStyle.display,
      textStyle: TextStyle(
        fontSize: (preferredStyle?.fontSize ?? 14) * 1.2,
      ),
    );
  }
}

// ─── 安全的 Math.tex 包裹器（onErrorFallback 替代全局 FlutterError.onError） ───

class _SafeMath extends StatelessWidget {
  final String tex;
  final MathStyle mathStyle;
  final TextStyle? textStyle;
  const _SafeMath({required this.tex, this.mathStyle = MathStyle.text, this.textStyle});

  @override
  Widget build(BuildContext context) {
    final m = Math.tex(
      tex,
      mathStyle: mathStyle,
      textStyle: textStyle,
      onErrorFallback: (e) => SelectableText(tex, style: textStyle),
    );
    if (mathStyle == MathStyle.text) {
      final br = m.texBreak();
      if (br.parts.length <= 1) return m;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: br.parts,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: m,
        ),
      ),
    );
  }
}
