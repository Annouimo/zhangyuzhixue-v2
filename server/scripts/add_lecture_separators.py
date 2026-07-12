"""
为讲义 Markdown 内容注入 <!-- pagebreak --> 和 <!-- reveal --> 分隔符。

规则：
  - 每个 ## 大节前插入 <!-- pagebreak -->（第一个 ## 前不插，因为第一页从 # 标题开始）
  - 同一页内每个 ### 小节前插入 <!-- reveal -->（该页第一个 ### 前不插，它是默认可见的 block[0]）

用法：
    python scripts/add_lecture_separators.py          # 注入并持久化
    python scripts/add_lecture_separators.py --dry    # 仅预览，不写入
"""
import re
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
os.environ['DJANGO_ALLOW_ASYNC_UNSAFE'] = 'true'

import django  # noqa: E402
django.setup()

from courses.models import Document  # noqa: E402


def inject_separators(md: str) -> str:
    """向 md_content 中插入 pagebreak 和 reveal 分隔符，返回新内容。"""
    lines = md.split('\n')
    result = []
    page_started = False
    first_heading_on_page = False

    for line in lines:
        stripped = line.strip()

        # ## 大节：触发 pagebreak
        if re.match(r'^##\s+\S', stripped):
            if page_started:
                result.append('')
                result.append('<!-- pagebreak -->')
                result.append('')
            page_started = True
            first_heading_on_page = True  # 下一个 ### 是页内第一个
            result.append(line)
            continue

        # ### 小节：触发 reveal（非本页第一个）
        if re.match(r'^###\s+\S', stripped):
            if page_started and not first_heading_on_page:
                result.append('<!-- reveal -->')
                result.append('')
            first_heading_on_page = False
            result.append(line)
            continue

        result.append(line)

    return '\n'.join(result)


def main():
    dry_run = '--dry' in sys.argv

    total = Document.objects.count()
    changed = 0

    for doc in Document.objects.iterator():
        if not doc.md_content:
            continue
        new_md = inject_separators(doc.md_content)
        if new_md == doc.md_content:
            continue

        changed += 1
        if dry_run:
            print(f'[{doc.id}] {doc.title} — 将修改 ({len(doc.md_content)} → {len(new_md)} chars)')
        else:
            doc.md_content = new_md
            doc.save(update_fields=['md_content'])
            print(f'[{doc.id}] {doc.title} — 已更新 ({len(doc.md_content)} → {len(new_md)} chars)')

    action = '预览' if dry_run else '修改'
    print(f'  {chr(187)} {total} 篇，{action} {changed} 篇')


if __name__ == '__main__':
    main()
