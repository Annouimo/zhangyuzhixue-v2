# 章鱼智学 v2 · 运行时审计 Skill 备查

> 用途：快速查阅各 skill 的职责、输入输出、调用时机。
> 最后更新：2026-07-14（新增 五、横切探查工具 cross-cut-investigation）

---

## 一、批量走查记录器

**skill 名：** `manual-audit-recorder`
**定位：** 你一次性给出全部操作清单（点击、SQL、截图等），agent 逐条执行并记录结果，最后输出 JSON。**不需要逐条指挥。**

| 项目 | 内容 |
|:----|:------|
| 输入 | 你一次性给的批量操作清单（模块号 + 步骤列表） |
| 输出 | `docs/auto-audit/审计日志/manual_audit_<模块号>_<日期>_<序号>.json` |
| 格式 | 与 fix-batch-workflow 的格式化输入兼容 |
| 何时用 | 你自己设计好走查步骤，让 agent 批量执行+记录 |

**步骤指令速查：**

| 你写 | agent 执行 |
|:----|:-----------|
| `snap` / `截图` | winnav_snap，自动记 OCR 文字 |
| `click <文字>` | winnav_click |
| `click_at <x> <y>` | winnav_click_at |
| `scroll -1.0` | winnav_scroll |
| `输入 <文字>` | winnav_type |
| `sql "<查询>"` | ecs_query.py sql |
| `check-user <用户名>` | ecs_query.py check-user |
| `read <路径>` | read_file |
| `wait <秒>` | 等 N 秒 |
| `记问题: <描述>, severity=<等级>` | 记录一个 ❌ bug |
| `记通过: <描述>` | 记录一个 ✅ pass |
| `记诊断: <根因>, path=<路径>` | 给上一个问题追加诊断 |

## 二、批量修复工作流

**skill 名：** `fix-batch-workflow`
**定位：** 拿到已知问题列表后，核实→出方案→等批准→执行→报告。**不做根因诊断。**

| 项目 | 内容 |
|:----|:------|
| 输入 | 问题列表（文字描述，或 JSON 格式） |
| 输出 | 对话：方案表 + 状态报告 |
| 何时用 | 已有明确的问题列表，需要系统性的核实+出方案+执行 |

**输入 JSON 格式**（可选，有则省去追问环节）：

```json
{
  "meta": { "module": 3 },
  "bugs": [
    {
      "id": "3.2",
      "page": "SolveChoicePage",
      "checklist_item": "冷却期间提交按钮禁用",
      "operation": "从作业进入选择题，冷却10s期间点击提交",
      "symptom": "按钮点击无响应，无禁用态样式",
      "severity": "🟡 非阻塞",
      "ocr_evidence": { "snapshot": "...", "visible_texts": [], "missing_texts": [] },
      "server_data": { "query": "SQL", "result": "..." },
      "diagnosis": { "root_cause": "...", "code_path": "...", "line_numbers": "...", "classification": "code-only" }
    }
  ]
}
```

**核实第 10 步（特殊门禁）：** 如果读完代码+设计文档仍找不到根因 → 暂停。不猜不修，等用户加载 `runtime-diagnosis-tools`。

---

## 三、根因诊断工具集

**skill 名：** `runtime-diagnosis-tools`
**定位：** 当 fix-batch-workflow 的核实步骤找不到根因时，升级到此 skill 深入排查。

| 项目 | 内容 |
|:----|:------|
| 输入 | 有症状但代码读不出根因的问题 |
| 输出 | 诊断结果文字（含 root_cause、code_path、line_numbers 等） |
| 何时用 | 代码读完了，问题表现仍然无法解释 |

**6 个诊断工具：**

| 工具 | 适用场景 |
|:----:|---------|
| 服务器数据核实 | UI 值不对但代码查询逻辑没问题 — 查三层链路（DB→构建产物→客户端） |
| NDJSON 崩溃链 | 白屏/闪退但代码无明显 bug — 4 个命令定位崩溃源头 |
| R12 模式 | 功能时好时坏/特定条件才复现 — 6 条规则匹配运行时异常模式 |
| 引擎交叉验证 | audit_engine 报 CERTAIN 但不确定是否误报 — 用 NDJSON 逐条验证 |
| Verify 基础设施 | ecs_query.py verify 返回空缓存 — 5 步排查链 |
| 修复类型标注 | 诊断完成后给每个问题打标签（code-only / design-sync / api-dependent 等） |

---

## 四、竞品心态审计

**skill 名：** `competitive-audit`
**定位：** 预设每段非固定文字是错的，上服务器证伪才能放行。以竞争者的心态挑刺，发现 7 条 bug 后暂停。

| 项目 | 内容 |
|:----|:------|
| 宪法规则 | 1) 有罪推定：所有非固定文字预设为错，ecs_query 验证才能放行；2) 无跳过机制；3) 7 bug 暂停；4) 🔴 立即停；5) vision 仲裁；6) 不预读后续步骤 |
| 输入 | 无（自动走查 Flutter App） |
| 输出 | `docs/auto-audit/审计日志/competitive_audit_<日期>.json` |
| 何时用 | 你想系统性地以竞品心态扫描整个 App，不放过任何可疑数据 |

**特有机制：**

| 机制 | 说明 |
|:----|:------|
| 有罪推定 | 看到数字（"6项未完成""共0题"）→ 预设是错的 → 查服务器 → 证伪才能放行 |
| 7 bug 暂停 | ❌+🔴+🟡 累计 7 条 → 立即暂停，输出阶段性报告，等用户批示 |
| vision 仲裁 | 怀疑工具误报 → snap → `vision_analyze(screenshot)` → 模型判断 |
| 冷却感知 | 解题页用 OCR 检测"还剩 X 秒"文字消失作为信号，不固定 sleep |
| OCR 容差 | 空格/标点/全半角差异忽略 |
| 步骤链 | 8 步递进，每步末尾指向下一步，agent 不预读 |

**步骤链一览：**

```
SKILL.md
 └─→ .hermes/tmp/competitive-audit/step-1-init.md     # 初始化 + 确认用户
       └─→ step-2-home.md                               # 首页走查
             └─→ step-3-homework.md                     # 待办作业列表
                   └─→ step-4-solve.md                   # 解题流程（冷却感知 + vision 仲裁）
                         └─→ step-5-recommend.md         # 推荐页
                               └─→ step-6-exam.md        # 组卷（含 🔴 隐私检查）
                                     └─→ step-7-profile.md  # 我的页
                                           └─→ step-8-finalize.md  # 汇总输出
```

**与 manual-audit-recorder 的区别：**

| 维度 | manual-audit-recorder | competitive-audit |
|:----|:---------------------|:-----------------|
| 角色 | 记录员（你指挥，它记录） | 审计员（自主走查，主动找茬） |
| 心态 | 中性 | 竞争者——预设每段文字是错的 |
| 暂停 | 你手动说停 | 发现 7 bug 自动暂停 |
| 仲裁 | 无 | vision_analyze 辅助判断 |
| 输入 | 你给操作清单 | 无（全自动） |

---

## 五者的协作关系

```
你手动走查（一次性清单）
    │
    ▼
manual-audit-recorder     ← 你指挥，agent 记录
    │
    │ 输出 JSON
    ▼
fix-batch-workflow         ← 拿到问题列表，核实→方案→执行
    │
    ├─ 代码读出了根因 → 直接出方案
    │
    └─ 代码读不出根因 → 暂停
         │
         ▼
      runtime-diagnosis-tools  ← 用户手动加载，深入排查
         │
         └─ 诊断结果 → 回到 fix-batch-workflow 继续

competitive-audit            ← 替代手动走查，全自动挑刺
    │
    │ 输出 JSON（格式与 manual-audit-recorder 兼容）
    ▼
fix-batch-workflow           ← 直接进入修复流程
```

---

## 五、横切探查工具

**skill 名：** `cross-cut-investigation`
**定位：** 输入一个模糊方向（"筛选""积分""作业""同步""解题"），在该方向横切整个技术栈，系统性地发现全部可能的问题。**不做修复，只做发现。**

| 项目 | 内容 |
|:----|:------|
| 输入 | 一个方向性主题（自然语言） |
| 输出 | 对话：JSON 格式探查报告，兼容 fix-batch-workflow 输入 |
| 何时用 | 你想全面扫查某个功能方向的所有问题，而不是给具体 bug 列表 |

**5 个探查维度（横切面）：**

| 维度 | 检查内容 | 核心方法 |
|:----:|---------|---------|
| ① UI 层 | 设计合规性：控件/状态/交互是否与 HTML 原型一致 | 对照设计文档读代码 |
| ② 数据流链路 | 从 UI 控件 → callback → state → Repository → DAO → SQL，逐层追踪参数不被丢弃 | 追踪链路，标记每层存活状态 |
| ③ 数据层完备性 | DAO 参数覆盖、Repository 组合、N-copy 一致性、类型转换安全 | 读 DAO/Repository 代码 |
| ④ 服务端 API | 端点存在性、请求响应匹配、权限过滤 | 仅涉及网络请求时执行 |
| ⑤ 边界情况 | 空数据崩溃、非法值处理、组合条件、异步安全、操作顺序 | 基于代码逻辑推演 |

**输出 JSON 格式（兼容 fix-batch-workflow）：**

```json
{
  "meta": { "topic": "筛选", "investigation_date": "2026-07-14" },
  "findings": [
    {
      "id": "F-01",
      "dimension": "数据流链路",
      "severity": "🔴 阻塞|🟡 非阻塞|⚪ 信息",
      "type": "UI-原型不符|数据断连|查询缺失|边界遗漏|代码异味",
      "title": "简短的标题",
      "evidence": { "file": "path/to/file.dart", "line": "L42-L55", "snippet": "...", "design_ref": "..." },
      "description": "完整问题描述",
      "suggested_next": "建议的后续步骤"
    }
  ]
}
```

**与四者的协作关系（更新版）：**

```
用户输入模糊方向:"探查一下筛选"
    │
    ▼
cross-cut-investigation    ← 新 skill：横切探查
    │ 发现 N 个问题
    │ 输出 JSON
    ▼
用户审阅 → 确认问题列表
    │
    ▼
fix-batch-workflow          ← 拿到问题列表，核实→方案→执行
    │
    ├─ 代码读出了根因 → 直接出方案
    │
    └─ 代码读不出根因 → 暂停
         │
         ▼
      runtime-diagnosis-tools  ← 深入排查
         │
         └─ 诊断结果 → 回到 fix-batch-workflow 继续
```

**与 manual-audit-recorder / competitive-audit 的区分：**

| 维度 | manual-audit-recorder | competitive-audit | cross-cut-investigation |
|:----|:---------------------|:-----------------|:-----------------------|
| 角色 | 记录员（你指挥，它记录） | 审计员（自动走查 App） | 分析师（静态代码探查） |
| 输入 | 你给的操作清单 | 无（全自动走查 Flutter App） | 一个模糊方向关键词 |
| 方法 | 操作 GUI + OCR 验证 | winnav 走查 + vision 仲裁 | 读文档 + 读代码 + 逐层追踪 |
| 产出 | 操作 JSON | 走查 JSON | 问题清单 JSON |
| 何时用 | 你设计好步骤让 agent 批量执行 | 你想自动扫 App 找茬 | 你想全面了解某个方向的代码问题 |

---

## 已删除的旧 skill（供参考，不再使用）

| skill | 原因 |
|:------|:-----|
| `runtime-verification` | 大一统 skill，agent 读不完 |
| `rv-phase1-walkthrough` | 拆分后设计不合理，被 manual-audit-recorder 替代 |
| `rv-phase2-diagnosis` | 重命名为 runtime-diagnosis-tools，全内联 |
| `rv-phase34-fix` | 与 fix-batch-workflow 重复 |
