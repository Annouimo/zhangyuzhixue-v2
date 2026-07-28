/// Markdown + LaTeX 渲染组件
///
/// 封装了 flutter_markdown_plus 与 flutter_math_fork 的集成，
/// 支持标准 Markdown + 行内公式 `$...$` + 块级公式 `$$...$$`。
///
/// ## 使用方式
///
/// ```dart
/// MdLatexBody('勾股定理：$a^2 + b^2 = c^2$')
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
class MdLatexBody extends StatelessWidget {
  final String data;
  final double fontSize;

  const MdLatexBody(this.data, {super.key, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return MarkdownBody(
      data: data,
      selectable: true,
      blockSyntaxes: const [_BlockMathSyntax()],
      inlineSyntaxes: const [_InlineLatexSyntax()],
      builders: const {
        'latex_inline': _InlineLatexBuilder(),
        'math_block': _BlockMathBuilder(),
      },
      styleSheet: _defaultStyle(context),
    );
  }

  static MarkdownStyleSheet _defaultStyle(BuildContext context) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: fontSize, color: Colors.black87, height: 1.6),
      h1: TextStyle(fontSize: fontSize + 6, fontWeight: FontWeight.bold, height: 1.4),
      h2: TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, height: 1.4),
      h3: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.w600, height: 1.4),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      code: TextStyle(fontSize: fontSize - 1, backgroundColor: Colors.grey[100], fontFamily: 'monospace'),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 行内公式 $...$
// ══════════════════════════════════════════════════════════

class _InlineLatexSyntax extends md.InlineSyntax {
  const _InlineLatexSyntax() : super(r'\$([^$]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('latex_inline', match[1]!));
    return true;
  }
}

class _InlineLatexBuilder extends MarkdownElementBuilder {
  const _InlineLatexBuilder();

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

// ══════════════════════════════════════════════════════════
// 块级公式 $$...$$
// ══════════════════════════════════════════════════════════

class _BlockMathSyntax extends md.BlockSyntax {
  const _BlockMathSyntax();

  @override
  RegExp get pattern => RegExp(r'^\$\$');

  @override
  bool canEndBlock(md.BlockParser parser) => true;

  @override
  md.Node parse(md.BlockParser parser) {
    final line = parser.current.content;
    final single = RegExp(r'^\$\$(.*)\$\$$').firstMatch(line);
    if (single != null) {
      parser.advance();
      return md.Element.text('math_block', single[1]!.trim());
    }
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
  const _BlockMathBuilder();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return _SafeMath(
      tex: element.textContent,
      mathStyle: MathStyle.display,
      textStyle: TextStyle(fontSize: (preferredStyle?.fontSize ?? 14) * 1.2),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 安全的 Math.tex 包裹器（onErrorFallback 替代全局 FlutterError.onError）
// ══════════════════════════════════════════════════════════

class _SafeMath extends StatelessWidget {
  final String tex;
  final MathStyle mathStyle;
  final TextStyle? textStyle;

  const _SafeMath({required this.tex, this.mathStyle = MathStyle.text, this.textStyle});

  @override
  Widget build(BuildContext context) {
    // flutter_math_fork's Math.build crashes on effectiveTextStyle.color!
    // when color is null (e.g. inside Markdown table header cells).
    final safeStyle = textStyle?.color != null
        ? textStyle
        : (textStyle?.copyWith(color: AppColors.textPrimary) ??
            TextStyle(color: AppColors.textPrimary));
    final m = Math.tex(
      tex,
      mathStyle: mathStyle,
      textStyle: safeStyle,
      onErrorFallback: (e) => SelectableText(tex, style: textStyle),
    );
    if (mathStyle == MathStyle.text) {
      dynamic br;
      try {
        br = m.texBreak();
      } catch (_) {}
      if (br == null || br.parts.length <= 1) return m;
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
