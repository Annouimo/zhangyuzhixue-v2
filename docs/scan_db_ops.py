"""Scan all HTML files in UI_Phase2 and generate db_inventory.html with all DB operations."""

import re
from pathlib import Path

UI_DIR = Path(r'D:\Hermes\zhangyuzhixue_app_v2\docs\UI_Phase2')
OUTPUT = Path(r'D:\Hermes\zhangyuzhixue_app_v2\docs\db_inventory.html')

records = []  # (page, path, type, description)


def _describe(path):
    descs = {
        'user.greeting': '问候语',
        'user.real_name': '用户姓名',
        'user.school': '学校标语',
        'user.student_id': '学号',
        'user.points': '当前积分',
        'user.history_count': '做题历史计数',
        'user.exam_count': '组卷历史计数',
        'home.recommend_count': '推荐说明',
        'auth.username': '用户名',
        'auth.password': '密码',
        'auth.invitation_code': '邀请码',
        'auth.real_name': '真实姓名',
        'auth.phone': '手机号',
        'auth.gaokao_year': '高考年份',
        'auth.password1': '密码',
        'auth.password2': '确认密码',
        'exam.name': '试卷名称',
        'exam.total_questions': '题目总数',
        'exam.selected_count': '已选计数',
        'exam.points_cost': '消耗积分',
        'exam.choice_count': '选择题数',
        'exam.fill_count': '填空题数',
        'exam.solve_count': '解答题数',
        'exam.total_count': '总题数',
        'assignment.title': '作业标题',
        'assignment.course_name': '所属课程',
        'assignment.completed': '已完成数',
        'assignment.total': '总题数',
        'assignment.deadline_remaining': '剩余天数',
        'question.title': '解题页面标题',
        'question.number': '题号',
        'question.assignment_name': '所属作业',
        'question.stem': '题干',
        'question.concepts': '相关概念',
        'question.congrats_text': '恭喜文字',
        'step.title': '步骤标题',
        'step.knowledge_card': '知识卡片',
        'step.content': '步骤解析',
        'rating.user_difficulty': '用户难度评分',
        'rating.user_calculation': '用户计算量评分',
        'rating.user_elegance': '用户优雅度评分',
        'rating.algorithm_difficulty': '算法难度分',
        'rating.algorithm_calculation': '算法计算量分',
        'lecture.title': '讲义标题',
        'lecture.content': '讲义正文',
        'lecture.page_info': '页码信息',
        'course.name': '课程名',
        'table_header.time': '表头-时间',
        'table_header.type': '表头-类型',
        'table_header.change': '表头-变动',
        'table_header.balance': '表头-余额',
        'table_header.note': '表头-说明',
    }
    return descs.get(path, '')


# Scan all files
for f in sorted(UI_DIR.glob('*.html')):
    content = f.read_text('utf-8')
    name = f.name

    # data-db (read only)
    for m in re.finditer(r'data-db="([^"]+)"', content):
        records.append((name, m.group(1), '📖 读取', _describe(m.group(1))))

    # data-db-bind (two-way)
    for m in re.finditer(r'data-db-bind="([^"]+)"', content):
        records.append((name, m.group(1), '🔄 双向绑定', _describe(m.group(1))))

    # data-db-action (write)
    for m in re.finditer(r'data-db-action="([^"]+)"', content):
        records.append((name, m.group(1), '✏️ 写入', ''))

    # data-db-loop (list)
    for m in re.finditer(r'data-db-loop="([^"]+)"', content):
        records.append((name, m.group(1), '🔁 循环列表', ''))

    # data-db-empty (empty state)
    for m in re.finditer(r'data-db-empty="([^"]+)"', content):
        records.append((name, m.group(1), '📭 空状态文案', ''))


# Build HTML
rows_html = ''
for page, path, typ, desc in records:
    rows_html += f'''    <tr>
      <td>{page}</td>
      <td><code>{path}</code></td>
      <td>{typ}</td>
      <td>{desc}</td>
    </tr>
'''

html = f'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>章鱼智学 - 数据库操作清单</title>
  <style>
    *, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: -apple-system, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
      background: #F5F7FA;
      color: #1A1A2E;
      padding: 24px;
      line-height: 1.6;
    }}
    h1 {{ font-size: 22px; margin-bottom: 4px; }}
    .subtitle {{ color: #6B7280; font-size: 14px; margin-bottom: 20px; }}
    table {{
      width: 100%;
      border-collapse: collapse;
      background: #fff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    }}
    th {{
      text-align: left;
      padding: 12px 14px;
      background: #4A6CF7;
      color: #fff;
      font-size: 14px;
      font-weight: 600;
    }}
    td {{
      padding: 10px 14px;
      border-bottom: 1px solid #E5E7EB;
      font-size: 13px;
    }}
    tr:hover td {{ background: #EEF1FF; }}
    code {{
      font-family: "Cascadia Code", "Fira Code", "Consolas", monospace;
      font-size: 12px;
      background: #F3F4F6;
      padding: 2px 6px;
      border-radius: 4px;
    }}
    .tag {{ display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 500; }}
    .tag-read {{ background: #DBEAFE; color: #1E40AF; }}
    .tag-bind {{ background: #FEF3C7; color: #92400E; }}
    .tag-write {{ background: #D1FAE5; color: #065F46; }}
    .tag-loop {{ background: #F3E8FF; color: #6B21A8; }}
    .tag-empty {{ background: #FCE4EC; color: #C62828; }}
    .count {{ font-size: 13px; color: #6B7280; margin-bottom: 12px; }}
    .legend {{ display: flex; gap: 16px; margin-bottom: 16px; flex-wrap: wrap; }}
    .legend-item {{ display: flex; align-items: center; gap: 6px; font-size: 13px; }}
  </style>
</head>
<body>
  <h1>📊 章鱼智学 · 数据库操作总清单</h1>
  <p class="subtitle">由 <code>scan_db_ops.py</code> 自动扫描生成 · 共 {len(records)} 项</p>

  <div class="legend">
    <div class="legend-item"><span class="tag tag-read">📖 读取</span> 从数据库取数据显示</div>
    <div class="legend-item"><span class="tag tag-bind">🔄 双向绑定</span> 表单输入，读取+写回</div>
    <div class="legend-item"><span class="tag tag-write">✏️ 写入</span> 用户操作触发写入</div>
    <div class="legend-item"><span class="tag tag-loop">🔁 循环列表</span> 列表循环渲染</div>
    <div class="legend-item"><span class="tag tag-empty">📭 空状态</span> 列表为空时的文案</div>
  </div>

  <p class="count">按页面分组，共 {len(set(r[0] for r in records))} 个页面</p>

  <table>
    <thead>
      <tr>
        <th>页面</th>
        <th>路径</th>
        <th>类型</th>
        <th>说明</th>
      </tr>
    </thead>
    <tbody>
{rows_html}    </tbody>
  </table>

  <p class="subtitle" style="margin-top:20px;">
    更新方式：在项目根目录运行 <code>python docs/scan_db_ops.py</code>
  </p>
</body>
</html>'''

OUTPUT.write_text(html, 'utf-8')
print(f'Done. Generated {OUTPUT} with {len(records)} records.')
