#!/usr/bin/env python3
import os, re
path = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\pdf\test_paper_v2.html'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Remove the info-table block
c = re.sub(
    r'\s*<table class="info-table">.*?</table>',
    '',
    c,
    flags=re.DOTALL
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)

# Verify
with open(path, 'r', encoding='utf-8') as f:
    c2 = f.read()
if 'info-table' in c2:
    print('WARNING: still present')
else:
    print('OK: info-table removed')
print(f'Size: {len(c2)} bytes')
