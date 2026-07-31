import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';

/// 渲染 Markdown + LaTeX 数学公式的组件
///
/// 基于 flutter_markdown + flutter_math_fork，支持：
/// - Markdown 语法（粗体、列表、标题等）
/// - LaTeX 数学公式（$$...$$ 行间、$...$ 行内）
/// - 自定义样式匹配设计系统
class MdLatexBody extends StatelessWidget {
  final String data;
  final double fontSize;

  MdLatexBody(this.data, {super.key, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      color: colors.textPrimary,
      height: 1.6,
    );
    if (data.isEmpty) return const SizedBox.shrink();
    return MarkdownBody(
      data: data,
      selectable: false,
      blockSyntaxes: [_BlockMathSyntax()],
      inlineSyntaxes: [_AnswerBlankSyntax(), _InlineLatexSyntax()],
      builders: {
        'answer_blank': _AnswerBlankBuilder(),
        'latex_inline': _InlineLatexBuilder(),
        'math_block': _BlockMathBuilder(),
      },
      styleSheet: MarkdownStyleSheet(
        p: bodyStyle,
        h1: (textTheme.headlineMedium ?? bodyStyle).copyWith(
          fontSize: fontSize + 6,
          color: colors.textPrimary,
          height: 1.4,
        ),
        h2: (textTheme.headlineSmall ?? bodyStyle).copyWith(
          fontSize: fontSize + 4,
          color: colors.textPrimary,
          height: 1.4,
        ),
        h3: (textTheme.titleMedium ?? bodyStyle).copyWith(
          fontSize: fontSize + 2,
          color: colors.textPrimary,
          height: 1.4,
        ),
        strong: bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        em: bodyStyle.copyWith(
          fontStyle: FontStyle.normal,
          color: colors.textSecondary,
        ),
        code: TextStyle(
          fontSize: fontSize - 1,
          backgroundColor: colors.surfaceSubtle,
          color: colors.textPrimary,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        blockquoteDecoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        listBullet: bodyStyle.copyWith(color: colors.textSecondary),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
      ),
    );
  }

}

// ─── 填空题答题空格 ───

/// 纯空白下划线不是数学公式。将题库中的
/// `$\underline{\hspace{2cm}}$` 保持为行内答题位，避免公式盒子居中。
class _AnswerBlankSyntax extends md.InlineSyntax {
  _AnswerBlankSyntax()
    : super(r'\$\\underline\{\\hspace\{([0-9.]+)(cm|em|pt)\}\}\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('answer_blank', '${match[1]}${match[2]}'));
    return true;
  }
}

class _AnswerBlankBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final fontSize = preferredStyle?.fontSize ?? 14;
    final width = _blankWidth(element.textContent, fontSize);
    return Semantics(
      label: '答题空格',
      child: Container(
        width: width,
        height: fontSize * 1.25,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: preferredStyle?.color ?? Colors.black,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  double _blankWidth(String value, double fontSize) {
    final match = RegExp(r'^([0-9.]+)(cm|em|pt)$').firstMatch(value);
    final amount = double.tryParse(match?.group(1) ?? '') ?? 2;
    switch (match?.group(2)) {
      case 'em':
        return amount * fontSize;
      case 'pt':
        return amount * 96 / 72;
      case 'cm':
      default:
        return amount * 96 / 2.54;
    }
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
      textStyle: TextStyle(fontSize: (preferredStyle?.fontSize ?? 14) * 1.2),
    );
  }
}

// ─── 安全的 Math.tex 包裹器（onErrorFallback 替代全局 FlutterError.onError） ───

class _SafeMath extends StatelessWidget {
  final String tex;
  final MathStyle mathStyle;
  final TextStyle? textStyle;
  _SafeMath({
    required this.tex,
    this.mathStyle = MathStyle.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // flutter_math_fork's Math.build crashes on effectiveTextStyle.color!
    // when color is null (e.g. inside Markdown table header cells).
    final safeStyle = textStyle?.color != null
        ? textStyle
        : (textStyle?.copyWith(color: colors.textPrimary) ??
              TextStyle(color: colors.textPrimary));
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(child: m),
            ),
          );
        },
      ),
    );
  }
}
