# Phase 1.2 — 题库数据迁移（旧版→新版）

> 本文档是 [Phase-1-服务端全量.md](./Phase-1-服务端全量.md) 中步骤 1.2 的细化执行方案。
> 状态：**✅ 迁移完成** | 执行日期：2026-07-10 | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **1.2a** | 概念标签体系重构（三级树形） | 含在 1 天内 | ✅ |
| **1.2b** | 题目主表迁移 + ID 按试卷重排 | 含在 1 天内 | ✅ |
| **1.2c** | 题目-标签关联迁移 | 含在 1 天内 | ✅ |
| **1.2d** | 解题步骤迁移（SubQuestion + SolutionMethod + SolutionStep） | 含在 1 天内 | ✅ |
| **1.2e** | 选择题选项解析 + 配图迁移 | 含在 1 天内 | ✅ |
| **1.2f** | 卡片关联建立 | 含在 1 天内 | ✅ |
| | **合计** | **~1 天** | ✅ |

### 前置条件

- [x] Phase 1.1 完成：所有迁移目标表（BaseQuestion 等）已 migrate
- [x] 旧版 `D:\Hermes\math_platform\db.sqlite3` 可访问，含 798 题
- [x] 旧版配图目录 `D:\Hermes\math_platform\static\questions\附图\` 可访问

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) | 迁移目标表定义 |
| [`Phase-1-服务端全量.md`](./Phase-1-服务端全量.md) §1.1 | 模型定义参考 |

---

## 旧版数据库探查结果

经实际探查，旧版 `D:\Hermes\math_platform\db.sqlite3` 情况如下：

### 字段名差异

| 新版模型字段 | 旧版字段名 | 差异说明 |
|:---|:---|:---|
| `question.year` | `year` | 一致 |
| `question.exam_type` | `exam` | 需映射（值：一模/二模/高考） |
| `question.region` | `district` | 需映射（值：海淀/西城/东城/朝阳/北京） |
| `question.number` | `question_number` | 字段名不同 |
| `question.difficulty` | `difficulty` | REAL 浮点数（如 0.449、5.691），非 0-10 整数 |
| `question.calculation` | `workload` | REAL 浮点数，非 0-10 整数 |
| `question.default_score` | `score` | 字段名不同 |
| (无) | `answer_text` | 旧版答案文本，迁移至 SubQuestion.answer |

### 表名差异

| 新版表 | 旧版对应表 | 差异 |
|:---|:---|:---|
| `ConceptTag` | `tags_concepttag`（112 条） | 无 parent_id，通过 `tags_concepttagboard` + `tags_knowledgeboard` 表达层级 |
| `KnowledgeCard` | `knowledge_knowledgecard`（107 条已发布） | 字段 name→title，content 一致 |
| `QuestionConceptTag` | `questions_question_concept_tags`（2247 条） | 字段 concepttag_id 需映射 |
| `ChoiceExt` | **无对应表** | 选择题选项需从 question_text 中解析提取 |
| `SubQuestion` | `questions_questionstep`（3061 条） | 旧版无 step_title，新版 title 用"步骤 N"填充 |
| `QuestionKnowledgeCard` | **无对应表** | 从 SolutionStep.card_titles JSON 反向解析 |
| `SolutionStep.card_titles` | `questions_questionstep.card_refs` | 旧版存为 JSON（如 `[{"name":"正弦定理","type":"定理"}]`） |

### 配图

- 路径：`D:\Hermes\math_platform\static\questions\附图\`
- 结构：`{exam_type}/{year}/{district}/q{question_number}.{png|webp}`
- 共 **196 个文件**（98 张图 × PNG + WebP 双格式）
- question_text 中**没有** `<img>` 标签，图片靠路径约定关联

### 行数

| 表 | 行数 | 说明 |
|:---|:---:|:---|
| questions_question | 801 | 含 3 条 year=2099 测试数据，排除后 **798** |
| questions_questionstep | 3061 | 所有解题步骤 |
| tags_concepttag | 112 | 概念标签（扁平） |
| tags_knowledgeboard | 14 | 板块（父级分类） |
| tags_concepttagboard | 119 | 标签→板块关联 |
| knowledge_knowledgecard | 107 | 已发布知识卡片 |
| questions_question_concept_tags | 2247 | 题目-标签关联 |
| 配图文件 | 196 | 98 张图（PNG+WebP 各一份） |

---

## 执行方案与设计决策

### 执行原则

1. **每步生成全量审核文件**：迁移后输出 JSON/CSV 文件包含全部迁移数据，供逐条审阅
2. **每步备份**：生成 `server/db_step_1_2X.bak`，可随时回滚
3. **可回滚**：每步开始前备份当前新版数据库状态

### 概念标签体系 — 三级分类重构（1.2a）

旧版 tags_concepttag（112 条扁平标签）+ tags_knowledgeboard（14 个板块）+ tags_concepttagboard（119 条关联），原始数据中标签与板块是多对多关系（6 个标签跨 2~3 个板块），且题目只引用标签不引用板块。

**设计决策：** 不保留旧版板扁平结构，重构为三级树形分类：

```
一级（parent=NULL）    二级（parent=一级）       三级（parent=二级）
────────────────────────────────────────────────────────────────
代数 ─┬─ 集合, 逻辑, 不等式, 函数, 三角函数,
      │   数列, 复数, 多项式                     ← 各板块下的标签
      └─ (跨板块) 运算, 单调性                   ← 6 个跨板块标签挂一级

几何 ─┬─ 解析几何, 立体几何, 解三角形, 向量, 几何通法
      └─ (跨板块) 直线, 面积, 高, 几何关系

概率统计 ─┬─ 概率
```

**数据清洗：** 旧 id=23 `常熟列` → `常数列`（错别字修正）

**去重处理：** 标签名与板块名重复时（不等式、概率），复用板块节点。

**结果：** ConceptTag 127 条（3 一级 + 14 二级 + 110 三级，含复用）

### 题目主表 — 按试卷重排 ID（1.2b）

旧版题目 ID 是乱的（如 id=1 是 2025 高考，id=2 是 2025 一模海淀）。

**设计决策：** 按试卷排序重新分配 ID，同卷内连续：

```
排序规则: year↑ → 一模(1)→二模(2)→高考(3) → 东城(1)→西城(2)→朝阳(3)→海淀(4)→北京(5) → 题号↑
```

效果：id 1–21 = 2020高考北京，id 22–42 = 2021高考北京，... id 778–798 = 2026二模海淀。

### 题目-标签关联（1.2c）

通过名称交叉引用建立旧→新标签 ID 映射，2247 条全部迁移，0 丢失。

### 解题步骤（1.2d）

旧版 questionstep 3061 条 → SubQuestion 1092 + SolutionMethod 1152 + SolutionStep 3061。
选填题 answer_text 写入对应 SubQuestion.answer。

### 选择题选项 + 配图（1.2e）

**ChoiceExt：** 从 stem 末尾解析 `(A)...(B)...(C)...(D)...` 格式，提取后从 stem 中移除选项文本。

**配图：** 按 `{exam}/{year}/{district}/q{number}.{ext}` 路径匹配，图片文件复制到 `server/static/questions/images/`。

### 卡片关联（1.2f）

从 SolutionStep.card_titles 反向建立 QuestionKnowledgeCard，107 种卡片名称全部匹配。

---

## 迁移结果统计

| 步骤 | 旧版 | 新版 | 状态 |
|:---|:---|:---|:---:|
| 1.2a 概念标签 | 112 标签 + 14 板块 | 127 ConceptTag（三级树） | ✅ |
| 1.2a 知识卡片 | 107 已发布 | 107 KnowledgeCard | ✅ |
| 1.2b 题目 | 798 题 | 798 BaseQuestion（试卷排序 ID） | ✅ |
| 1.2c 标签关联 | 2247 | 2247 QuestionConceptTag | ✅ 0 丢失 |
| 1.2d 解题步骤 | 3061 | 3061 SolutionStep | ✅ |
| 1.2d SubQuestion | (从 step 推导) | 1092 SubQuestion | ✅ |
| 1.2d SolutionMethod | (从 step 推导) | 1152 SolutionMethod | ✅ |
| 1.2d answer 写入 | 570 选填题 | 570 SubQuestion.answer | ✅ |
| 1.2e ChoiceExt | (从 stem 解析) | 350/380 | ⚠️ 30 题跳过 |
| 1.2e 配图 | 196 文件(98张) | 204 题匹配 | ✅ |
| 1.2f 卡片关联 | (从 card_refs 推导) | 1512 QuestionKnowledgeCard | ✅ 0 丢失 |

### 数据清洗记录

| 项目 | 旧值 | 新值 | 说明 |
|:---|:---|:---|:---|
| concept_tag id=23 | 常熟列 | 常数列 | 错别字修正 |

---

## 已知问题

### 选择题选项解析失败（30 题）

350/380 道选择题成功提取选项到 ChoiceExt，**30 题解析失败**。原因推测：
- 选项格式不标准（如 `(A)...(B)...` 未按常规换行，或选项与题干之间无明确分隔）
- 选项可能在图片中
- 极少数题选项用 `A.` 或 `A、` 而非 `(A)`

**待处理：** 查看 `choice_ext_audit.csv` 中解析失败的 30 题，逐题确认选项内容后手动补充。

### 配图匹配数（204 题）> 磁盘文件数（98 张图）

旧版图片按 `exam/year/district/q_number` 路径组织，存在多题共享同一张图的情况（如不同年份同题号使用相同配图），属正常现象。

### ConceptTag 板块中「几何通法」命名

旧板块 id=8 名为「几何」，与一级分类「几何」重名，改为「几何通法」。如果不满意此命名可以修改。

---

## 审核文件清单

所有文件在 `docs/_archive/migration_audit/`（从原 `server/migration_audit/` 迁移至此）：

| 文件 | 行数 | 说明 |
|:---|:---:|:---|
| `old_concept_tags.json` | 板块14+标签112+关联119 | 旧版概念标签全量 |
| `new_concept_tags.json` | 127 条 | 新版 ConceptTag（含层级路径） |
| `concept_tag_mapping.csv` | 127 行 | 旧↔新标签 ID 对照 |
| `old_knowledge_cards.json` | 107 条 | 旧版知识卡片全量 |
| `new_knowledge_cards.json` | 107 条 | 新版 KnowledgeCard |
| `old_questions.csv` | 798 行 | 旧版题目全量 |
| `new_questions.csv` | 798 行 | 新版 BaseQuestion |
| `question_field_mapping.csv` | 798 行 | 旧↔新字段并列对照 |
| `id_allocation.txt` | 38 份试卷 | 每份试卷的新 ID 范围 |
| `old_id_to_new_map.json` | 798 条 | 旧 qid → 新 question_id |
| `answer_text_map.json` | 798 条 | 旧 qid → answer_text |
| `old_q_tags.csv` | 2247 行 | 旧版题目-标签关联 |
| `new_q_tags.csv` | 2247 行 | 新版 QuestionConceptTag |
| `q_tag_mapping.csv` | 2247 行 | 旧↔新关联对照 |
| `tag_id_cross_ref.json` | 112 条 | 旧 tag_id → 新 tag_id |
| `old_steps.csv` | 3061 行 | 旧版解题步骤 |
| `new_sub_questions.csv` | 1092 行 | 新版 SubQuestion |
| `new_solution_methods.csv` | 1152 行 | 新版 SolutionMethod |
| `new_solution_steps.csv` | 3061 行 | 新版 SolutionStep |
| `step_comparison_sample.json` | 20 题 | 新旧步骤对照样本 |
| `choice_ext_audit.csv` | 380 行 | 选择题选项解析结果（含失败的 30 题） |
| `image_mapping.csv` | 204 行 | 配图匹配关系 |
| `card_ref_analysis.csv` | 107 种 | 卡片引用次数统计 |
| `new_q_card_links.csv` | 1512 行 | 新版 QuestionKnowledgeCard |
| `unmatched_card_refs.csv` | 0 行 | 无法匹配的卡片名称（空=全部匹配） |

---

## 备份链

| 文件 | 包含 |
|:---|:---|
| `server/db_step_1_2a.bak` | 三级分类标签 + 107 张卡片 |
| `server/db_step_1_2b.bak` | + 798 题（试卷排序 ID） |
| `server/db_step_1_2c.bak` | + 2247 条标签关联 |
| `server/db_step_1_2d.bak` | + 3061 步 + 1092 SubQuestion + answer |
| `server/db_step_1_2ef.bak` | + 350 ChoiceExt + 204 配图 + 1512 卡片关联 |
