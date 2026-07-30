import html

import markdown
from django.utils.safestring import mark_safe


SEPARATORS = {
    '&lt;!-- pagebreak --&gt;': (
        'LECTURE_PAGEBREAK_SEPARATOR', '分页分隔', '此处在学生端开始新的一页',
    ),
    '&lt;!-- reveal --&gt;': (
        'LECTURE_REVEAL_SEPARATOR', '内容分隔', '此处在学生端分为下一个展开内容',
    ),
}


def render_lecture_markdown(source):
    """安全渲染内部讲义 Markdown，并将客户端分隔符变成提示线。"""
    escaped = html.escape(source or '')
    for marker, (token, _label, _description) in SEPARATORS.items():
        escaped = escaped.replace(marker, f'\n\n{token}\n\n')
    rendered = markdown.markdown(
        escaped, extensions=['extra', 'sane_lists'], output_format='html5',
    )
    for _marker, (token, label, description) in SEPARATORS.items():
        divider = (
            '<div class="lecture-separator" role="separator">'
            f'<strong>{label}</strong><span>{description}</span></div>'
        )
        rendered = rendered.replace(f'<p>{token}</p>', divider)
    return mark_safe(rendered)
