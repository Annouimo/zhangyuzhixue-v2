#!/usr/bin/env python3
"""Generate 4 PDF layout variants for comparison."""
import os

base = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\pdf'
src = os.path.join(base, 'test_paper.html')

with open(src, 'r', encoding='utf-8') as f:
    original = f.read()

# ── Variants ──────────────────────────────────────────────

# V1: 个人信息在标题附近（填实），章鱼智学在页脚
v1 = original.replace(
    '<td>姓名：<span class="blank">&nbsp;</span></td>\n      <td>班级：<span class="blank">&nbsp;</span></td>\n      <td>学号：<span class="blank">&nbsp;</span></td>',
    '<td>姓名：张三</td>\n      <td>班级：高三(1)班</td>\n      <td>学号：G2026001</td>'
).replace(
    'content: "— ',
    'content: "章鱼智学 — '
)

# V2: 个人信息 + 章鱼智学都在页脚
# Title area: remove info table, keep title block clean
v2 = original.replace(
    '  <table class="info-table">\n      <tr>\n        <td>姓名：<span class="blank">&nbsp;</span></td>\n      <td>班级：<span class="blank">&nbsp;</span></td>\n      <td>学号：<span class="blank">&nbsp;</span></td>\n    </tr>\n  </table>',
    ''
).replace(
    '  margin-bottom: 1.2em;\n  padding-bottom: 0.6em;',
    '  margin-bottom: 1.5em;\n  padding-bottom: 0.8em;'
)
# Add footer with info + branding (fixed position for print)
footer_v2 = '''  <!-- 页脚（个人信息 + 平台标识，仅打印可见） -->
  <div class="print-footer">
    <div class="pf-info">张三 · 高三(1)班 · G2026001</div>
    <div class="pf-brand">章鱼智学</div>
  </div>
</div>
</div>

<style>
@media print {
  .print-footer {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    text-align: center;
    font-size: 9pt;
    color: #999;
    padding: 4pt 0;
    border-top: 0.25pt solid #ccc;
    margin: 0 3.17cm;
  }
  .pf-info { margin-bottom: 2pt; }
}
</style>'''
v2 = v2.replace(
    '</div>\n</div>\n\n</body>\n</html>',
    footer_v2 + '\n</body>\n</html>'
)

# V3: 章鱼智学 + 个人信息都在标题附近
v3 = original.replace(
    '<div class="title-block">\n  <h1 class="paper-title">',
    '<div class="title-block">\n  <div class="brand-label">章鱼智学</div>\n  <h1 class="paper-title">'
).replace(
    '<td>姓名：<span class="blank">&nbsp;</span></td>\n      <td>班级：<span class="blank">&nbsp;</span></td>\n      <td>学号：<span class="blank">&nbsp;</span></td>',
    '<td>姓名：张三</td>\n      <td>班级：高三(1)班</td>\n      <td>学号：G2026001</td>'
)
# Add brand CSS
css_add = '.brand-label { font-size: 9pt; color: #666; letter-spacing: 1pt; margin-bottom: 4pt; }\n'
v3 = v3.replace('.paper-title {', css_add + '.paper-title {')

# ── Write files ───────────────────────────────────────────
files = {
    'test_paper_v1.html': v1,
    'test_paper_v2.html': v2,
    'test_paper_v3.html': v3,
}
for name, content in files.items():
    path = os.path.join(base, name)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Created: {name} ({len(content)} bytes)')

print('\nDone. 4 versions ready:')
print('  test_paper.html   — 原版（不变）')
print('  test_paper_v1.html — 个人信息在标题（填实），章鱼智学在页脚')
print('  test_paper_v2.html — 标题区简洁（去信息表），章鱼智学+个人信息在页脚')
print('  test_paper_v3.html — 章鱼智学+个人信息都在标题附近')
