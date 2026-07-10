# Phase 1.2 — 题库数据迁移（旧版→新版）

> 本文档是 Phase 1 中步骤 1.2 的细化执行方案。
> 状态：**方案等待审批** | 更新日期：2026-07-10

---

## 一、旧版数据库探查结果

经实际探查，旧版 `D:\Hermes\math_platform\db.sqlite3` 情况如下：

### 1.1 字段名差异

| 新版模型字段 | 旧版字段名 | 差异说明 |
|:---|:---|:---|
| `question.year` | `year` | 一致 |
| `question.exam_type` | `exam` | **需映射**（值：一模/二模/高考） |
| `question.region` | `district` | **需映射**（值：海淀/西城/东城/朝阳/北京） |
| `question.number` | `question_number` | **字段名不同** |
| `question.difficulty` | `difficulty` | REAL 浮点数（如 0.449、5.691），**非 0-10 整数** |
| `question.calculation` | `workload` | REAL 浮点数，**非 0-10 整数** |
| `question.default_score` | `score` | **字段名不同** |
| (无) | `answer_text` | 旧版答案文本，迁移至 SubQuestion.answer |

### 1.2 表名差异

| 新版表 | 旧版对应表 | 差异 |
|:---|:---|:---|
| `ConceptTag` | `tags_concepttag`（112 条） | 无 parent_id，用 `tags_concepttagboard` + `tags_knowledgeboard` 表达层级 |
| `KnowledgeCard` | `knowledge_knowledgecard`（107 条已发布） | 字段 name→title，content 一致 |
| `QuestionConceptTag` | `questions_question_concept_tags`（2247 条） | 字段 concepttag_id 需映射 |
| `ChoiceExt` | **无对应表** | 选择题选项需从 question_text 中解析提取 |
| `SubQuestion` | `questions_questionstep`（3061 条） | 旧版无 step_title，新版 title 用"步骤 N"填充 |
| `QuestionKnowledgeCard` | **无对应表** | 从 SolutionStep.card_titles JSON 反向解析 |

### 1.3 配图

- 路径：`D:\Hermes\math_platform\static\questions\附图\`
- 结构：`{exam_type}/{year}/{district}/q{question_number}.{png|webp}`
- 共 **196 个文件**（98 张图 × PNG + WebP 双格式）
- question_text 中**没有** `<img>` 标签，图片靠路径约定关联

### 1.4 行数

| 表 | 行数 | 说明 |
|:---|:---|:---|
| questions_question | 801 | 含 3 条 year=2099 测试数据，排除后 **798** |
| questions_questionstep | 3061 | 所有解题步骤 |
| tags_concepttag | 112 | 概念标签（扁平） |
| tags_knowledgeboard | 14 | 板块（父级分类） |
| tags_concepttagboard | 119 | 标签→板块关联 |
| knowledge_knowledgecard | 107 | 已发布知识卡片 |
| questions_question_concept_tags | 2247 | 题目-标签关联 |
| 配图文件 | 196 | 98 题有配图（PNG+WebP 各一份） |

---

## 二、迁移步骤划分

### 执行原则

1. **每步生成全量审核文件**：迁移后输出 JSON/CSV 文件包含**全部**迁移数据，供逐条审阅
2. **全量对比**：输出旧版原始数据 + 新版迁移后数据的对比文件
3. **审核通过再下一步**：你确认上一步数据无误后，再执行下一步
4. **可回滚**：每步开始前备份当前新版数据库状态

### 全量审核文件格式

每次迁移后生成以下文件到 `server/migration_audit/` 目录：

| 文件 | 内容 | 审核方式 |
|:---|:---|:---|
| `step_X_old_dump.json` | 旧版源表的**全部行** | 用文本编辑器或 JSON Viewer 查看 |
| `step_X_new_dump.json` | 新版目标表的**全部行**（含 id 映射） | 同上 |
| `step_X_comparison.txt` | 关键字段的旧→新对照（每行一条） | 逐行审阅 |
| `step_X_stats.txt` | 行数统计、值分布统计 | 快速概览 |

---

### 步骤 1.2a — 概念标签体系迁移

**涉及旧表：** `tags_concepttag`（112条） + `tags_knowledgeboard`（14条） + `tags_concepttagboard`（119条）

**迁移逻辑：**
1. 旧版 `tags_knowledgeboard`（集合/逻辑/不等式/函数...）→ 新版 `ConceptTag`，name 保持原名，parent=NULL
2. 旧版 `tags_concepttag`（运算/圆/直线...）→ 新版 `ConceptTag`，parent=对应板块
3. 保存旧 id → 新 id 映射供后续步骤使用

**全量审核文件：**
| 文件 | 内容 |
|:---|:---|
| `old_concept_tags.json` | 旧版全部 112 条概念标签 + 14 个板块 |
| `new_concept_tags.json` | 新版全部 126 条 ConceptTag（含旧id→新id映射） |
| `concept_tag_mapping.csv` | 每条：旧.id, 旧.name, 新.id, 板块名（parent） |

**审核要点：**
- 每个旧标签是否归到了正确的板块？
- 有无重复/丢失的标签？

---

### 步骤 1.2b — 题目主表迁移

**涉及旧表：** `questions_question`（801条，排除3条year=2099后798条）

**迁移逻辑：**
1. 读取旧版全部题目（排除 year=2099）
2. 字段映射：
   - `exam` → `exam_type`
   - `district` → `region`
   - `question_number` → `number`
   - `score` → `default_score`
   - `difficulty` → `difficulty`（原样，REAL浮点）
   - `workload` → `calculation`（原样，REAL浮点）
   - `question_type` 中文→枚举：选择题→choice，填空题→fill，解答题→solution
   - `question_text` → `stem`（保持原样，旧版不含 `<img>` 标签）
   - `images` 暂时为空（后续步骤根据路径匹配填充）
3. 保存旧 id → 新 id 映射

**全量审核文件：**
| 文件 | 内容 |
|:---|:---|
| `old_questions.csv` | 旧版 798 题的全部字段（CSV，可用 Excel 打开） |
| `new_questions.csv` | 新版 798 题 BaseQuestion 的全部字段（含旧id） |
| `question_field_mapping.csv` | 每行：旧id → 新id + 关键字段新旧值并列 |

**审核要点：**
- 行数 798 是否准确
- 随机挑 10-20 题逐字段对比旧版↔新版
- difficulty/workload 值是否原样保留
- question_type 映射是否正确
- stem 内容是否完好（尤其含 LaTeX 的）

---

### 步骤 1.2c — 题目-概念标签关联迁移

**涉及旧表：** `questions_question_concept_tags`（2247条）

**迁移逻辑：**
1. 读取旧版全部关联
2. 用旧 id → 新 id 映射（概念标签 + 题目）创建 `QuestionConceptTag`
3. 跳过映射失败的记录（报 warning）

**全量审核文件：**
| 文件 | 内容 |
|:---|:---|
| `old_q_tags.csv` | 旧版 2247 条关联（question_id, concepttag_id） |
| `new_q_tags.csv` | 新版全部 QuestionConceptTag（含映射后的新 id） |
| `q_tag_comparison.csv` | 旧 question_id → question_number + 标签名 |

**审核要点：**
- 随机抽 5 题检查标签是否与原版一致
- 有关联丢失的情况吗？

---

### 步骤 1.2d — 解题步骤迁移（SubQuestion → SolutionMethod → SolutionStep）

**涉及旧表：** `questions_questionstep`（3061条）

**迁移逻辑：**
1. 从旧版 questionstep 按 `(question_id, subquestion, method)` 分组
2. 对每个 `(question_id, subquestion)`：
   - 创建 `SubQuestion`，sort_order=subquestion，parent=NULL
   - 选填题（question_type=choice/fill）只有 subquestion=0 的一行
3. 对每个 `(question_id, subquestion, method)`：
   - 创建 `SolutionMethod`，sort_order=method，method_name=NULL（旧版无名称）
4. 对每个 step 行：
   - 创建 `SolutionStep`，step_number=step，content 原样
   - **title** = "步骤 {step_number}"（旧版无 step_title）
   - **card_titles** = 从 card_refs JSON 解析，提取每个元素的 name 字段
   - 如 `[{"name":"正弦定理","type":"定理"},{"name":"化简","type":"流程"}]` → `["正弦定理","化简"]`
5. 将旧版 `answer_text` 写入对应的 SubQuestion.answer（选填题的答案）

**全量审核文件：**
| 文件 | 内容 |
|:---|:---|
| `old_steps.csv` | 旧版全部 3061 条 questionstep |
| `new_sub_questions.csv` | 新版全部 SubQuestion |
| `new_solution_methods.csv` | 新版全部 SolutionMethod |
| `new_solution_steps.csv` | 新版全部 SolutionStep（含 title + card_titles） |
| `step_comparison_by_question/` | 按题号组织，每道题一个 txt 文件：旧版步骤 ↔ 新版步骤对照 |

**审核要点：**
- 选填题是否只有 1 行 subquestion？
- 解答题的子步骤是否完整？
- card_titles 解析是否正确？
- title="步骤 N" 是否可接受（旧版无标题）？
- answer_text 是否正确写入了对应的 SubQuestion？

---

### 步骤 1.2e — 选择题选项提取 + 配图关联

**涉及对象：** question_text + 配图文件系统

**迁移逻辑：**
1. **ChoiceExt 解析**：
   - 对所有 question_type=choice 的题目
   - 从 stem 末尾解析 `(A)...(B)...(C)...(D)...` 格式
   - 提取四个选项内容，写入 `ChoiceExt.options` JSON
   - 从 stem 中移除选项文本（stem 只保留题干部分）
2. **配图关联**：
   - 遍历磁盘 `附图/{一模|二模|高考}/{year}/{district}/q{question_number}.webp`
   - 匹配题目 → 在 BaseQuestion.images 中填入相对路径
   - 例如：一模/2023/海淀/q15.webp → images=["一模/2023/海淀/q15.webp"]

**全量审核文件：**
| 文件 | 内容 |
|:---|:---|
| `choice_questions_with_options.json` | 所有选择题：题号 + 原始 stem + 提取的 options + 清理后的 stem |
| `choice_ext.csv` | 新版 ChoiceExt 全部记录 |
| `image_mapping.csv` | 旧 exam_type/year/district/q_number → 新 question_id |
| `questions_with_images.csv` | 有配图的 98 题清单 |

**审核要点：**
- 选择题的 (A)(B)(C)(D) 选项提取是否正确？
- 清理选项后的 stem 是否保留完整题干？
- 配图路径是否正确匹配？

---

### 步骤 1.2f — 题目-知识卡片关联建立

**涉及数据：** SolutionStep.card_titles（从 card_refs 提取）

**迁移逻辑：**
1. 遍历所有 SolutionStep 的 card_titles
2. 按 card_title 名称查找 KnowledgeCard
3. 建立 QuestionKnowledgeCard 关联
4. 跳过找不到名称的记录（报 warning）

**全量审核文件：**
| 文件 | 内容 |
|:---|:---|
| `card_ref_analysis.csv` | 所有 card_refs 中引用的卡片名称 + 出现次数统计 |
| `new_q_card_links.csv` | 新版 QuestionKnowledgeCard 全部记录（question_id → card_title） |
| `unmatched_card_refs.csv` | 旧版 card_refs 中提到了但旧版 knowledge_knowledgecard 中不存在的名称 |

**审核要点：**
- 各卡片被引用的次数是否合理？
- 有无无法匹配的卡片名称？

---

## 三、迁移后全量验证

所有 6 步完成后，执行最终验证脚本，输出：

| 编号 | 验证项 | 审核文件 |
|:---|:---|:---|
| V1 | 总题数 798 | 旧版 798 vs 新版 BaseQuestion 798 |
| V2 | 逐题字段对比（抽 20 题） | 旧版↔新版关键字段并列呈现 |
| V3 | difficulty/workload 值一致性 | 随机 10 题对比值 |
| V4 | 步骤完整性 | 旧 3061 vs 新版 SolutionStep 行数 |
| V5 | 标签关联完整性 | 旧 2247 vs 新版 QuestionConceptTag 行数 |
| V6 | 配图匹配 | 磁盘 196 文件 vs images 字段引用 |
| V7 | 选择题选项 | 旧 question_text 选项 vs ChoiceExt JSON |
| V8 | 卡片关联 | 旧 card_refs 解析 vs 新版 QuestionKnowledgeCard |

最终输出一个 `full_audit_report.html`，将所有对比结果汇总成一份可翻阅的 HTML 报告。

---

## 四、如何审核每步数据

每步执行后，我将在 `server/migration_audit/` 目录下生成 CSV/JSON 文件。你可以用以下方式审阅：

### 方式 A：Excel 打开 CSV
- 所有 CSV 文件可直接用 Excel 打开
- 筛选、排序、对比都方便
- 同时打开旧版和新版 CSV 并列对比

### 方式 B：文本编辑器看 JSON
- JSON 文件保留完整数据结构
- 推荐 VS Code + JSON Viewer 插件
- 可搜索特定题号或字段值

### 方式 C：直接查数据库
迁移后你也可用 SQLite 浏览器（如 DB Browser for SQLite）直接打开新版 `server/db.sqlite3`，执行 SQL 查询任意数据。

---

## 五、执行流程

```
[你批准方案]
    ↓
[1.2a: 概念标签] → 生成审核文件 → [你审核 126 条数据]
    ↓                                 (同意/修改意见)
[1.2b: 题目主表] → 生成审核文件 → [你审核 798 题]
    ↓
[1.2c: 题目标签] → 生成审核文件 → [你审核 2247 条关联]
    ↓
[1.2d: 解题步骤] → 生成审核文件 → [你审核 3061 步]
    ↓
[1.2e: 选项+配图] → 生成审核文件 → [你审核 378 题选项 + 98 张配图]
    ↓
[1.2f: 卡片关联] → 生成审核文件 → [你审核关联数据]
    ↓
[最终全量验证报告]
```

---

## 附录：旧版关键 SQL 查询

执行迁移前，你自己也可以在旧版库上运行以下查询确认数据：

```sql
-- 1. 总题数（排除测试数据）
SELECT COUNT(*) FROM questions_question WHERE year != 2099;

-- 2. 题型分布
SELECT question_type, COUNT(*) FROM questions_question
WHERE year != 2099 GROUP BY question_type;

-- 3. 某道题的全部步骤
SELECT qq.id, qq.question_number, qs.subquestion, qs.method, qs.step,
       substr(qs.content, 1, 60) as content_preview
FROM questions_question qq
JOIN questions_questionstep qs ON qs.question_id = qq.id
WHERE qq.id = 794  -- 替换为你要查的题
ORDER BY qs.subquestion, qs.method, qs.step;

-- 4. 某道题的标签
SELECT t.name
FROM questions_question_concept_tags qt
JOIN tags_concepttag t ON t.id = qt.concepttag_id
WHERE qt.question_id = 760;

-- 5. 查看配图路径结构
SELECT exam, district, question_number
FROM questions_question
WHERE year=2023 AND exam='一模';
```

---

> 相关文档：
> - [数据库结构设计.md](../02-数据/数据库结构设计.md)
> - [00-落地计划.md](../00-落地计划.md) — Phase 1 概览
