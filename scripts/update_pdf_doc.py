import os
path = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\PDF方案设计.md'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# 1. Architecture data flow
c = c.replace(
    '│    ├── 查询 custom_paper + questions            │\n'
    '│    ├── 查询 choice_ext（选项）、question（图片路径）│\n'
    '│    ├── 组装 HTML（KaTeX CDN + CSS 模板）         │',
    '│    ├── 查询 custom_paper + questions            │\n'
    '│    ├── 查询 student -> nickname + student_id      │\n'
    '│    ├── 查询 choice_ext（选项）、question（图片路径）│\n'
    '│    ├── 组装 HTML（KaTeX + CSS + 页脚个人信息）    │'
)

# 2. View code - add student info query
c = c.replace(
    '    # 3. 组装 sections, 查 choice_ext, 查图片路径\n'
    '    # 4. 渲染 HTML 模板\n'
    '    return render(request, "pdf/paper_view.html", {\n'
    '        "title": title,\n'
    '        "sections": sections,\n'
    '    })',
    '    # 3. 查询 student 个人信息（页脚昵称+学号）\n'
    '    student_info = Student.objects.select_related("user").get(id=student.id)\n'
    '\n'
    '    # 4. 组装 sections, 查 choice_ext, 查图片路径\n'
    '    # 5. 渲染 HTML 模板\n'
    '    return render(request, "pdf/paper_view.html", {\n'
    '        "title": title,\n'
    '        "sections": sections,\n'
    '        "student_nickname": student_info.user.username,\n'
    '        "student_id": student_info.student_id,\n'
    '    })'
)

# 3. Template description
c = c.replace(
    '复用 pdf/test_paper.html 的 CSS + 排版规范。服务端侧只需：\n'
    '- 将 KaTeX CDN 从 cdn.jsdelivr.net 改为**使用本地托管版本**（Django static/），避免 CDN 加载延迟',
    '复用 pdf/test_paper.html 的 CSS + 排版规范。服务端侧只需：\n'
    '- 在 @page @bottom-right 的 content 中通过 Django 模板变量注入昵称和学号\n'
    '- 将 KaTeX CDN 从 cdn.jsdelivr.net 改为**使用本地托管版本**（Django static/），避免 CDN 加载延迟'
)

# 4. Layout spec table - update name area, add footer rows
c = c.replace(
    '| 姓名区 | 标题下方：姓名/班级/学号填空线 |',
    '| 姓名区 | 不在标题区展示，个人信息移至页脚 |'
)
c = c.replace(
    '| 页码 | CSS @page @bottom-center 自动生成，格式 — N — |',
    '| 页码 | CSS @page @bottom-center 自动生成，格式 — N — |\n'
    '| 页脚品牌 | @page @bottom-left：章鱼智学 |\n'
    '| 页脚个人信息 | @page @bottom-right：昵称+学号，服务端渲染注入 |'
)

# 5. Decision log
c = c.replace(
    '| PDF 下载扣分 | 不扣 | 组卷时已扣积分，PDF 是输出格式而非独立消费 |',
    '| PDF 下载扣分 | 不扣 | 组卷时已扣积分，PDF 是输出格式而非独立消费 |\n'
    '| 个人信息渲染 | 服务端从 JWT 解析 student_id 后查询，@page 模板变量注入 | sig 中已含 student_id，不额外 API 调用 |'
)

# 6. TODO update
c = c.replace(
    '| 8 | HTML 模板（基于 	est_paper.html） | server/templates/pdf/paper_view.html |',
    '| 8 | HTML 模板（基于 	est_paper.html）+ 个人信息注入 | server/templates/pdf/paper_view.html |'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('PDF方案设计.md updated')
