#!/usr/bin/env python3
import os
path = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\pdf\test_paper_v2.html'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Remove unused CSS rules
c = c.replace('.info-table { width: 100%; border-collapse: collapse; font-size: 10pt; margin-top: 0.5em; }\n.info-table td { padding: 0.2em 0.5em; width: 33%; text-align: left; }\n.blank { display: inline-block; min-width: 6em; border-bottom: 0.5pt solid #333; margin-left: 0.3em; }', '')

# Remove the .paper-subtitle line too since it's styling nothing
# (keep it for now, it's harmless)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)

with open(path, 'r', encoding='utf-8') as f:
    c2 = f.read()
if 'info-table' in c2:
    # Might be the CSS minified differently, check
    import re
    matches = re.findall(r'\.info-table\b', c2)
    print(f'info-table refs remaining: {len(matches)}')
else:
    print('OK: all unused CSS removed')
print(f'Size: {len(c2)} bytes')
