import os, shutil
base = r'D:\Hermes\zhangyuzhixue_app_v2\docs\03-服务端\pdf'
src = os.path.join(base, 'test_paper_v2.html')
dst = os.path.join(base, 'test_paper.html')
shutil.copy2(src, dst)
print('Copied v2 -> test_paper.html')
with open(dst, 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('张三 高三(1)班', '张三 G2026001')
with open(dst, 'w', encoding='utf-8') as f:
    f.write(c)
print('Updated footer: 张三 G2026001')
for name in ['test_paper_v1.html', 'test_paper_v2.html', 'test_paper_v3.html']:
    path = os.path.join(base, name)
    if os.path.exists(path):
        os.remove(path)
        print(f'Deleted {name}')
print('Done')
