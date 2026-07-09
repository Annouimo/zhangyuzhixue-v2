# MdLatexBody — Markdown + LaTeX 渲染组件

## 概述

在 Flutter 中渲染含 LaTeX 数学公式的 Markdown 文本。纯 Flutter 原生渲染，无需 WebView。

- **Markdown** 渲染：`flutter_markdown_plus`（GFM 标准，含表格、代码高亮、列表、引用等）
- **LaTeX** 渲染：`flutter_math_fork`（纯 Dart 实现，完全离线）
- 支持行内公式 `$...$` 和块级公式 `$$...$$`（单行/多行两种格式）

## 集成步骤

### 1. 添加依赖

```yaml
# pubspec.yaml
dependencies:
  flutter_markdown_plus: ^1.0.7
  flutter_math_fork: ^0.7.3
```

### 2. 复制组件文件

将 `md_latex_body.dart` 复制到项目任意位置，推荐：

```
lib/widgets/md_latex_body.dart
```

### 3. 在代码中使用

```dart
import 'package:你的项目/widgets/md_latex_body.dart';

// 简单使用
MdLatexBody(data: '勾股定理：$a^2 + b^2 = c^2$')

// 自定义样式
MdLatexBody(
  data: markdownContent,
  styleSheet: MarkdownStyleSheet(
    p: TextStyle(fontSize: 16, color: Colors.black87),
    h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
)

// 可选中文本
MdLatexBody(
  data: content,
  selectable: true,
)
```

## 支持的 Markdown 语法

| 语法 | 示例 | 支持 |
|------|------|------|
| 标题 | `# 一级` / `## 二级` | ✅ |
| 粗体/斜体 | `**粗体**` / `*斜体*` | ✅ |
| 删除线 | `~~删除~~` | ✅ |
| 无序列表 | `- 项` / `* 项` | ✅ |
| 有序列表 | `1. 项` | ✅ |
| 引用 | `> 引用` | ✅ |
| 代码行内 | `` `code` `` | ✅ |
| 代码块 | ` ```python ... ``` ` | ✅ 语法高亮 |
| 表格 | `\| 列1 \| 列2 \|` | ✅ |
| 链接 | `[文字](url)` | ✅ |
| 图片 | `![alt](url)` | ✅ |

## 支持的 LaTeX 语法

### 行内公式 `$...$`

```
欧拉公式：$e^{i\pi} + 1 = 0$
导数：$\frac{d}{dx}e^x = e^x$
```

### 块级公式 `$$...$$`

**单行写法：**
```
$$a^2 + b^2 = c^2$$
```

**多行写法：**
```
$$
f(x) = \int_{-\infty}^{\infty} \hat{f}(\xi) e^{2\pi i \xi x} \,d\xi
$$
```

### 支持的 LaTeX 命令

参见 [flutter_math_fork 文档](https://pub.dev/packages/flutter_math_fork) —— 支持 KaTeX 子集，包括：

- 运算符：`+ - \times \pm \cdot`
- 分式：`\frac{a}{b}`
- 根号：`\sqrt[n]{x}`
- 积分：`\int \iint \oint`
- 极限：`\lim \sum \prod`
- 矩阵：`\begin{matrix} ... \end{matrix}`
- 方程组：`\begin{cases} ... \end{cases}`
- 希腊字母：`\alpha \beta \pi \Sigma \theta`
- 花体：`\mathcal \mathbb \mathbf`
- 括号：`\left( \right) \bigl \bigr`
- 箭头：`\to \rightarrow \Rightarrow`
- 关系符：`\approx \neq \equiv \propto`

## 实现原理

```
输入文本 (Markdown + $...$ + $$...$$)
    │
    ├── BlockSyntax 拦截 $$...$$ ──→ flutter_math_fork 渲染块级公式
    │
    └── InlineSyntax 拦截 $...$  ──→ flutter_markdown_plus MarkdownBody
                                                │
                                            flutter_math_fork 渲染行内公式
```

- `_BlockMathSyntax` 匹配行首 `$$`，支持单行 `$$...$$` 和多行 `$$\n...\n$$`
- `_InlineLatexSyntax` 匹配行内 `$...$`
- 两种语法分别生成标签 `math_block` 和 `latex_inline`，由对应的 Builder 渲染
- Builder 使用 `flutter_math_fork` 的 `Math.tex()` 进行纯原生渲染

## 迁移注意事项

如果从 `flutter_markdown`（已废弃）迁移过来：

| 旧 | 新 |
|---|---|
| `import 'package:flutter_markdown/...'` | `import 'package:flutter_markdown_plus/...'` |
| `MarkdownBody(data: ..., extensionSet: ...)` | `MdLatexBody(data: ...)` 或 `MarkdownBody(blockSyntaxes: ..., inlineSyntaxes: ...)` |

## 调试项目

完整 demo 位于 `D:\Hermes\zhangyuzhixue_app_v2\debug`，包含 6 个渲染区块的示例。
