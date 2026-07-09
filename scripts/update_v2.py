#!/usr/bin/env python3
import os
base = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\pdf'
path = os.path.join(base, 'test_paper_v2.html')
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Replace the page rule: add @bottom-right with personal info
old = '@page { size: A4; margin: 2.54cm 3.17cm 2.54cm 3.17cm; @bottom-left { content: "章鱼智学"; font-family: SimSun, serif; font-size: 9pt; color: #999; } @bottom-center { content: "— " counter(page) " —"; font-family: SimSun, serif; font-size: 9pt; color: #666; } }'
new = '@page { size: A4; margin: 2.54cm 3.17cm 2.54cm 3.17cm; @bottom-left { content: "章鱼智学"; font-family: SimSun, serif; font-size: 9pt; color: #999; } @bottom-center { content: "— " counter(page) " —"; font-family: SimSun, serif; font-size: 9pt; color: #666; } @bottom-right { content: "张三 高三(1)班"; font-family: SimSun, serif; font-size: 9pt; color: #999; } }'

c = c.replace(old, new)
with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('V2 done')
print('  footer: 左=章鱼智学  中=—N—  右=张三 高三(1)班')
