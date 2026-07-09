#!/usr/bin/env python3
"""Update V1 and V2 layouts."""
import os

base = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\pdf'
old_page = '@page { size: A4; margin: 2.54cm 3.17cm 2.54cm 3.17cm; @bottom-center { content: "— " counter(page) " —"; font-family: SimSun, serif; font-size: 9pt; color: #666; } }'

# V1: @bottom-left brand + @bottom-center page number
path_v1 = os.path.join(base, 'test_paper_v1.html')
with open(path_v1, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    '@page { size: A4; margin: 2.54cm 3.17cm 2.54cm 3.17cm; @bottom-center { content: "\u7ae0\u9c7c\u667a\u5b66 \u2014 " counter(page) " \u2014"; font-family: SimSun, serif; font-size: 9pt; color: #666; } }',
    '@page { size: A4; margin: 2.54cm 3.17cm 2.54cm 3.17cm; @bottom-left { content: "\u7ae0\u9c7c\u667a\u5b66"; font-family: SimSun, serif; font-size: 9pt; color: #999; } @bottom-center { content: "\u2014 " counter(page) " \u2014"; font-family: SimSun, serif; font-size: 9pt; color: #666; } }'
)

with open(path_v1, 'w', encoding='utf-8') as f:
    f.write(c)
print('V1 done')

# V2: remove fixed footer, use @bottom-left brand + @bottom-center page number
path_v2 = os.path.join(base, 'test_paper_v2.html')
with open(path_v2, 'r', encoding='utf-8') as f:
    c = f.read()

# Remove the position:fixed footer block (from comment to </style>)
marker = '<!-- \u9875\u811a'
if marker in c:
    c = c.split(marker)[0]
c = c.rstrip() + '\n</div>\n</div>\n\n</body>\n</html>\n'

# Update @page 
new_page = '@page { size: A4; margin: 2.54cm 3.17cm 2.54cm 3.17cm; @bottom-left { content: "\u7ae0\u9c7c\u667a\u5b66"; font-family: SimSun, serif; font-size: 9pt; color: #999; } @bottom-center { content: "\u2014 " counter(page) " \u2014"; font-family: SimSun, serif; font-size: 9pt; color: #666; } }'
if old_page in c:
    c = c.replace(old_page, new_page)

with open(path_v2, 'w', encoding='utf-8') as f:
    f.write(c)
print('V2 done')

for name in ['test_paper_v1.html', 'test_paper_v2.html']:
    sz = os.path.getsize(os.path.join(base, name))
    print(f'  {name}: {sz} bytes')
