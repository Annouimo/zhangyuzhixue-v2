with open('D:/Hermes/zhangyuzhixue_app_v2/docs/数据库结构设计.md', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the question_id line in submission_detail table
insert_after = -1
for i, line in enumerate(lines):
    if 'question_id' in line and 'FK' in line and 'question.id' in line and 'NOT NULL' in line:
        insert_after = i
        break

if insert_after >= 0:
    attempt_line = '| `attempt_number` | INTEGER | NOT NULL, DEFAULT 1 | 同一 question_id 内从 1 递增，= 第几次作答 |\n'
    status_line = "| `status` | VARCHAR | NOT NULL, DEFAULT 'in_progress' | in_progress / completed |\n"
    lines.insert(insert_after + 1, attempt_line)
    lines.insert(insert_after + 2, status_line)

    for i, line in enumerate(lines):
        if 'submission_id' in line and 'NOT NULL' in line:
            lines[i] = '| `submission_id` | FK → submission.id | nullable | 作业提交则关联，免费练习为 null |\n'
            break

    with open('D:/Hermes/zhangyuzhixue_app_v2/docs/数据库结构设计.md', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print('OK')
else:
    print('NOT FOUND')
