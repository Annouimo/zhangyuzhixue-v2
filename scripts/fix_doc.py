import os
path = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\PDF方案设计.md'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Fix layout table - add footer rows
c = c.replace(
    '| 页码 | CSS `@page @bottom-center` 自动生成，格式 `\u2014 N \u2014` |\n| 页眉页脚 | 学生在打印对话框中取消勾选即可 |',
    '| 页码 | CSS `@page @bottom-center` 自动生成，格式 `\u2014 N \u2014` |\n| 页脚品牌 | `@page @bottom-left`：章鱼智学 |\n| 页脚个人信息 | `@page @bottom-right`：昵称+学号，服务端渲染注入 |\n| 页眉页脚 | 学生在打印对话框中取消勾选即可 |'
)

# Fix TODO 
c = c.replace(
    '| 8 | HTML 模板（基于 `test_paper.html`） | `server/templates/pdf/paper_view.html` |',
    '| 8 | HTML 模板（基于 `test_paper.html`） + 个人信息注入 | `server/templates/pdf/paper_view.html` |'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('OK')
