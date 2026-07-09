/// Markdown + LaTeX 渲染组件
///
/// 封装了 flutter_markdown_plus 与 flutter_math_fork 的集成，
/// 支持标准 Markdown + 行内公式 `$...$` + 块级公式 `$$...$$`。
///
/// ## 使用方式
///
/// ```dart
/// MdLatexBody(
///   data: '勾股定理：$a^2 + b^2 = c^2$',
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

// ══════════════════════════════════════════════════════════
// 公开 Widget
// ══════════════════════════════════════════════════════════

/// 渲染含 LaTeX 数学公式的 Markdown 文本。
///
/// [data] — Markdown 字符串，支持 `$...$` 行内公式和 `$$...$$` 块级公式。
/// [styleSheet] — 可选，覆盖 Markdown 默认样式。
/// [selectable] — 是否可选中文本，默认 false。
class MdLatexBody extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final bool selectable;

  const MdLatexBody({
    super.key,
    required this.data,
    this.styleSheet,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      blockSyntaxes: [_BlockMathSyntax()],
      inlineSyntaxes: [_InlineLatexSyntax()],
      builders: {
        'latex_inline': _InlineLatexBuilder(),
        'math_block': _BlockMathBuilder(),
      },
      styleSheet: styleSheet ?? _defaultStyle(context),
    );
  }

  static MarkdownStyleSheet _defaultStyle(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineSmall,
      h2: theme.textTheme.titleLarge,
      p: theme.textTheme.bodyMedium,
      code: TextStyle(
        backgroundColor: Colors.grey.shade200,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 行内公式 $...$
// ══════════════════════════════════════════════════════════

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
    return Math.tex(
      element.textContent,
      mathStyle: MathStyle.text,
      textStyle: TextStyle(
        fontSize: preferredStyle?.fontSize ?? 14,
        color: preferredStyle?.color,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 块级公式 $$...$$
// ══════════════════════════════════════════════════════════

class _BlockMathSyntax extends md.BlockSyntax {
  _BlockMathSyntax();

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Math.tex(
          element.textContent,
          mathStyle: MathStyle.display,
          textStyle: TextStyle(
            fontSize: (preferredStyle?.fontSize ?? 14) * 1.2,
          ),
        ),
      ),
    );
  }
}
