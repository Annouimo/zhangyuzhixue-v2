# 章鱼智学 v2 · 运行时审计 Skill 备查

> 用途：快速查阅各 skill 的职责、输入输出、调用时机。
> 最后更新：2026-07-13

---

## 一、手动走查记录器

**skill 名：** `manual-audit-recorder`
**定位：** 你指挥，agent 执行并记录。适合手动走查时当书记员。

| 项目 | 内容 |
|:----|:------|
| 输入 | 你逐条发指令（点击、SQL、读文件等） |
| 输出 | `docs/auto-audit/审计日志/manual_audit_<模块号>_<日期>_<序号>.json` |
| 格式 | 与 fix-batch-workflow 的格式化输入兼容 |
| 何时用 | 你自己走查页面，让 agent 执行工具操作+记录结果 |

**常用指挥指令：**
- `snap` / `截图` → winnav_snap
- `点 签到` / `click 待办作业` → winnav_click
- `点 x=0.1 y=0.2` → winnav_click_at
- `向下滚` / `scroll -1.0` → winnav_scroll
- `输入 test_audit` → winnav_type
- `sql SELECT count(*) FROM ...` → ecs_query.py sql
- `查 test_audit` → ecs_query.py check-user
- `读 lib/pages/xxx.dart` → read_file
- `记一个问题` → 引导补全 bug 字段
- `保存` / `输出` → 写入 JSON

---

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

## 三者的协作关系

```
你手动走查
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
```

---

## 已删除的旧 skill（供参考，不再使用）

| skill | 原因 |
|:------|:-----|
| `runtime-verification` | 大一统 skill，agent 读不完 |
| `rv-phase1-walkthrough` | 拆分后设计不合理，被 manual-audit-recorder 替代 |
| `rv-phase2-diagnosis` | 重命名为 runtime-diagnosis-tools，全内联 |
| `rv-phase34-fix` | 与 fix-batch-workflow 重复 |
