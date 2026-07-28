import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributionHelpPage extends StatelessWidget {
  const ContributionHelpPage({super.key});

  static final Uri _latexLive = Uri.parse('https://www.latexlive.com/');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Markdown 与 LaTeX 说明')),
    body: AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _section(context, '数学公式', r'''行内公式使用 `$...$`，例如：函数 $f(x)=x^2$。

独立公式使用 `$$...$$`：

$$
f(x)=\frac{1}{x}+\sqrt{x+1}
$$'''),
          _section(context, '常用写法', r'''- 分式：`\frac{a}{b}`
- 根式：`\sqrt{x+1}`
- 上下标：`x^2`、`a_n`
- 区间：`\left(0,1\right]`
- 求和：`\sum_{k=1}^{n}k`
- 极限：`\lim_{x\to 0}f(x)`'''),
          _section(
            context,
            'JSON 中的反斜杠',
            r'''在普通编辑框中写 `\frac`，在 JSON 字符串中必须写成 `\\frac`。

导入成功后，编辑表单会恢复为普通 LaTeX，不需要继续写双反斜杠。''',
          ),
          _section(
            context,
            'Markdown',
            '''使用空行分段，使用 `**重点内容**` 表示强调，也可以使用有序或无序列表。请勿粘贴 HTML、脚本、Markdown 图片或完整的 LaTeX 文档。''',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('可视化公式编辑', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'LaTeXLive 支持可视化编辑、实时预览和 JSON 字符串转义。第三方网站可能提供图片识别，请勿上传包含个人信息的内容。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: '打开 LaTeXLive',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => launchUrl(
                    _latexLive,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ),
  );

  Widget _section(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          MdLatexBody(body, fontSize: 15),
        ],
      ),
    ),
  );
}
