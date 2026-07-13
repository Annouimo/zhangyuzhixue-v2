# 章鱼智学 · 运行时审计流程手册

> **版本：** v3.2 | **最后更新：** 2026-07-13
> **对应 Skill：** `runtime-verification`
> **代替：** 旧版全量走查→R→Vision 模式（已废弃）

---

## 🚀 快速启动

复制以下任意一句到 Hermes 对话中即可开始走查：

```
🤖 对 agent 说：/skill runtime-verification 执行 模块0（前置准备），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块1（登录/注册/引导），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
...
```

> **注意：** 模块有依赖顺序（如模块 7 需要先做模块 3 的题），建议从 0→1→2→... 依次执行。遇到崩溃会自动暂停诊断，修完再继续。

---

## ⚖️ 宪法级规则

| 规则 | 内容 |
|:----:|:------|
| **规则 0** | **动手前先证伪。** 任何假设先找证据推翻它，找不到再相信 |
| **规则 1** | **代码只读一遍。** Phase 2 读完，Phase 3 直接引用行号，不重读 |
| **规则 2** | **核心工具故障→停下报告。** 不搞降级绕行，绕行浪费的时间更多 |

---

## 核心理念：五步闭环，走一段修一段

不再是一次性跑完全部页面再出报告。而是**走查→诊断→方案审批→落地执行→验证循环**，直到排查清单全部 ✅。

```
┌─ ① winnav 走查模块
│     遇到崩溃→立即暂停；完成模块→暂停
│     数据异常但不阻塞→继续走，记下来
│         ↓
│  ② 诊断+核实（NDJSON + engine + 读代码）
│     代码只读一遍，输出代码已读清单
│         ↓
│  ③ 方案审批（出方案→等批准）
│     基于②的结果，不重读代码
│         ↓
│  ④ 落地执行（改代码+文档→测试→提交）
│         ↓
│  ⑤ 验证循环→回到 ①
└─────────────────────── 循环
```

### 两组工具

| 组别 | 工具 | 角色 |
|:----:|------|:----:|
| 🖱️ **操作** | winnav MCP Server（5 个工具） | 截图/OCR/点击/滚动/关闭，驱动 app 走查 |
| 🔍 **排查+修复** | NDJSON + audit_engine + ecs_query.py | 诊断根因→核实验证→出方案→执行→提交 |

---

## 前置条件

### 环境

| 项目 | 要求 |
|:----|:----:|
| 桌面 | 不锁屏，窗口不被遮挡 |
| 窗口 | Flutter app 已通过 `flutter run --dart-define=AUDIT_MODE=true` 启动并登录 |
| 其它 | 关闭/最小化 Hermes 桌面客户端等可能冲突的 Flutter 窗口 |
| 账号 | `test_audit` / `test123`（服务器端预创建，见模块 0） |
| NDJSON | 自动写入 `%TEMP%/zhangyuzhixue_audit.ndjson` |
| winnav | `hermes mcp list` 确认已注册并启用 |
| **预取数据** | `python docs/auto-audit/ecs_query.py verify <模块号>` — 走查前必须执行 |

### 新工作流：verify → page

```bash
# Step 0：走查前先预取服务器数据（一次性 SSH）
python docs/auto-audit/ecs_query.py verify 2
# → 缓存到 .verify_cache/module_2.json

# Step 1：走查中逐页读取服务器预期值
python docs/auto-audit/ecs_query.py page 2 index.html
# → 只输出 index.html 页面的所有 data-db 路径 + 服务器值
# → 用于逐项 OCR 对照（匹配 ✅ / 不匹配 ❌）
```

**为什么改：** 之前 `verify` 一次 dump 所有页面到终端，内容过长，agent 不便查找。现在按页读取，粒度对齐走查流程。

**数据不匹配排查方向：** 如果 OCR 显示值与 `page` 命令输出的服务器预期值不一致，按链路逐级排查：**(1) 本地 UI 展示问题**（Widget 读错字段/未刷新）；**(2) 同步问题**（服务器有数据但客户端未同步）；**(3) 服务器问题**（数据未生成/接口返回错误）；**(4) ecs_query 脚本问题**（DATA_DB_MAP 映射路径错误或 worker 查询 SQL 有误）。从最靠近 DB 的环节查起，排除干净再向前端推进。

### winnav MCP 快速参考

| 工具 | 用途 | 关键参数 |
|:----:|------|---------|
| `winnav_init` | 找窗口+置前+截图+OCR | `window_class` 默认 `FLUTTER_RUNNER_WIN32_WINDOW`, `window_title` 默认 `flutter_app` |
| `winnav_snap` | 截图+OCR（~0.6s） | `label` 可选，用于命名截图 |
| `winnav_type` | 在当前焦点处输入文字 | `text` 必填；`interval` 默认 0.05s（字符间隔） |
| `winnav_click` | OCR 定位文字并点击 | `text` 必填；`exact` 默认 false；`y_range=[min, max]` 过滤 y 百分比范围 |
| `winnav_click_at` | 锚点百分比+像素偏移点击 | `x_pct`, `y_pct` 锚点；`dx`, `dy` 偏移 |
| `winnav_mouse_pos` | 读取鼠标位置 | 配合 `click_at` 的 `dx/dy` 校准坐标 |
| `winnav_scroll` | 按窗口高度百分比滚动 | `dy` 负值=向下，-1.0=向下一整屏 |
| `winnav_close` | 释放 OCR 缓存，输出完整 JSON 操作日志 | 每次走查结束必须调用 |

**核心设计：** 所有坐标用百分比（窗口相对），不涉及像素。截图到 `%TEMP%/winnav/screenshots/`。

---

## 完整流程

### Step 0 — 前置准备（模块 0）

**👤 你在 ECS 上执行：**

- [ ] 构建题库数据：`python scripts/build_assets.py --test && python scripts/build_lectures.py --test`
- [ ] 生成邀请码：Admin → `/admin/system/tools/` → 数量 5、有效期 30 天
- [ ] 创建作业：Admin 中创建 2 份 HomeworkAssignment，assign 给 test_audit
- [ ] 创建公开组卷：创建 2 份试卷 → 设为公开
- [ ] 确认讲义数据：调 `GET /api/v1/lectures/courses/` 返回非空
- [ ] 确认 test_audit 账号存在：Admin 中查 User 表

**👤 你在本地执行：**

```bash
cd D:\Hermes\zhangyuzhixue_app_v2\flutter_app
flutter run --dart-define=AUDIT_MODE=true
```

确认 `✓ Built build\windows\x64\runner\Debug\flutter_app.exe` 后，app 窗口出现。不要关闭终端。

---

### Step 1 — 走查：winnav 逐项排查

**🤖 agent 执行：** 按 `docs/auto-audit/基础功能排查清单.md` 中定义的模块 1 起逐项走查。

> **走查心态：排查清单是保底，不是天花板。**
> 看到"同步""刷新""重试"等按钮主动点击试试。
> 弹窗/toast/error banner 先记录再关闭，不得跳过。
> 做得比清单多可以，不能比清单少。

#### 1a. 页面全景扫描（不可跳过）

进入模块起始页后，先执行全景扫描再开始跑清单：

```
□ snap() 截图
□ 扫描 OCR：banner / 弹窗 / Toast
□ 对每个动作按钮：点击探索
□ 对每个弹窗：读完→记录→关闭
□ 检查 LaTeX 反斜杠
□ 记下 phase1a_done: true
□ 然后开始走清单
```

#### 标准操作序列

```python
# 1. 初始化
winnav_init()

# 2. 截图
winnav_snap(label="页面名")

# 3. 读取服务器预期值
# python ecs_query.py page <模块号> <当前页面名.html>
# → 输出当前页 data-db 路径的服务器值，用于 OCR 对照

# 4. OCR 定位点击
winnav_click(text="按钮文字")
winnav_click(text="精确文字", exact=True)

# 5. 处理同文字歧义（如顶部 ← vs 底部 ←）
winnav_click(text="←", y_range=[0.9, 1.0])

# 6. Icon 按钮 → 锚点+偏移
winnav_click_at(x=0, y=1.0, dx=<偏移>)

# 7. 滚动
winnav_scroll(dy=-1.0)

# 8. 走查结束
winnav_close()
```

#### 暂停规则

| 条件 | 动作 |
|:----|:----:|
| **崩溃/白屏** | 🔴 立即暂停，**先输出检查点**，再进入诊断 |
| **模块完成** | ✅ 暂停，**输出检查点**，进入诊断 |
| **❌ 占比 > 40%** | ⏸ 提前暂停，**输出检查点** |
| **用户中断** | 立即中止工具调用，等待指令，**输出检查点** |
| 数据异常但可操作 | ➡ 记入清单，继续走 |
| winnav 找不到按钮 | ➡ 记入清单，尝试绕过 |

**所有暂停都必须输出【状态检查点】**，用 `completed: false` 标记未完成。

#### 心跳与进度汇报

每 10 次工具调用或每 3 个检查项，输出一句进度提示：
`⏳ 进度：已完成 模块2.1 ~ 2.4，当前正在执行 模块2.5...`

#### 状态检查点

完成一个模块或暂停时输出：

```json
{
  "session_id": "audit_<日期>",
  "last_module": <模块号>,
  "last_checklist_item": "<模块号>.<检查项号>",
  "pending_bugs": <N>,
  "total_bugs": <N>,
  "phase1a_done": <true/false>,
  "completed": <true/false>
}
```

**走查顺序：** 模块 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

---

### Step 2 — 诊断 + 核实（代码只读一遍）

暂停后执行。**代码只读一遍，Phase 3/4 不重读文件。**

#### 2a. 分支判断

- **崩溃/白屏** → 直接跳 2c（崩溃链诊断）
- **数据异常** → 按序执行 2b→2c→2d→2e→2f

#### 2b. 服务器核实（优先于一切）

当 ❌ 涉及服务器持有状态时，先查服务器再查客户端：

```bash
python docs/auto-audit/ecs_query.py health
python docs/auto-audit/ecs_query.py count questions
python docs/auto-audit/ecs_query.py check-user test_audit
python docs/auto-audit/ecs_query.py sql "SELECT COUNT(*) FROM system_systemconfig"
python docs/auto-audit/ecs_query.py models Assignment
```

**输出标记：** `server-confirmed-bug` / `client-data-inconsistency` / `data-missing`

#### 2c. 崩溃链诊断

```powershell
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json |
  Where-Object cat -eq 'page' | Sort-Object seq -Descending | Select-Object -First 5
```

#### 2d. R 引擎

```bash
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R
```

CERTAIN / LIKELY / SUSPICIOUS 三级输出。**引擎是工具不是 oracle**，你需要用自己的推理判断。

#### 2e. Server-Driven 对比

```sql
SELECT COUNT(*) FROM qbank_basequestion;     -- ~799
SELECT COUNT(*) FROM courses_assignment;      -- ~4
SELECT COUNT(*) FROM courses_course;          -- ~2
SELECT COUNT(*) FROM system_systemconfig;     -- ~17
```

#### 2f. R12 模式分析

| 子规则 | 查什么 | 级别 |
|:-----:|--------|:----:|
| R12.1 | 冷启动前 10 条内 `ensureOpen`/`Bad state` | CERTAIN |
| R12.2 | 同 DAO ≥20 次且全 0 行 → N+1 | SUSPICIOUS |
| R12.3 | page 有日志但零 API 条目 | CERTAIN |
| R12.4 | 两页面间 ≥100 条非 page 日志 | LIKELY |
| R12.5 | 预期页数 vs 实际页数 | CERTAIN/LIKELY |
| R12.6 | `vt='null'` 且 `val=''` → 空串误报 | SUSPICIOUS |

#### 2g. 读代码确认根因

打开 ❌ 涉及的文件，确认根因行号。**记录文件+行号，输出代码已读清单**（`- file.dart:Lxx-Lyy` 格式）。

布局溢出、TemporaryNode 崩溃、翻页栏不匹配等具体诊断 → 见 `references/layout-overflow-and-pager-diagnostics.md` 等。

#### 2h. 查 git history

`git log --all --oneline --grep=<keyword>` → `already-fixed` / `partially-fixed` / `needs-fix`

#### 2i. 读设计文档对照

HTML 原型（最高权威）> 设计说明 .md > 排查清单。不一致时**等你拍板**。

#### 2j. 标注修复类型

`code-only` / `design-sync` / `api-dependent` / `infrastructure` /
`data-exists-but-not-wired` / `data-missing`

#### 2k. 分解复合问题 + 搜影响点

一个 ❌ 可能对应多个根因，分解为子问题。涉及命名概念时 grep 全项目。

#### 2l. 输出诊断结果

已核实+已分类+已分解的 ❌ 列表，直接进入 Step 3。

---

### Step 3 — 方案审批

**只出方案+等批准。** 不碰代码、不执行改动。

**自我审计：** 输出方案前，回顾 Step 2 的【代码已读清单】，确认所有行号均出自该清单。

输出方案表（每个 ❌ 必须有行号+代码片段）：

```
## 修改方案

| # | 问题 | 文件:行号 | 改动 | 类型 |
|---|------|:---------:|------|:----:|
| 1 | ... | file.dart:94-99 | _submit 改为 async+持久化 | code-only |
```

规则：
- 不因"更简单"就提交简化方案
- 无 stub / TODO
- 如果代码 > 设计文档，方案必须包含文档更新

**等批准：** 输出方案后停止。等你说了"执行吧"后再进入 Step 4。

---

### Step 4 — 落地执行

**核心：基于已批准的方案执行改动。** 不新增方案内容、不改设计。

#### 4a. 执行

1. 按方案列表一次执行所有改动
2. 设计文档与代码同步更新
3. `git add` 只加本次修复的文件
4. `git diff --cached --stat` 确认 staging 区干净

#### 4b. 测试

```
Flutter:  dart analyze && flutter test
Server:   pytest server/scripts/tests/ && flake8 --config .flake8
```

测试失败则修。不允许宣布"部分成功"。

#### 4c. 提交

```bash
git commit -m "fix: N项问题修复 — <摘要>"
```

#### 4d. 状态报告

对话形式输出：总览 → 逐项明细 → 测试结果 → 提交 hash。

---

### Step 5 — 验证循环

1. **👤 你：** 重新 `flutter run --dart-define=AUDIT_MODE=true`
2. **🤖 agent：**
   - grep 对话历史中最后一个检查点
   - 如果 `phase1a_done == false` → 重做全景扫描
   - 如果 `phase1a_done == true` → 跳 `last_checklist_item + 1`
   - 验证已修复 ❌ 是否通过
   - 继续走查未完成的检查项
3. 循环回到 Step 1

---

## 常见问题

### app 已启动但 winnav_init 返回「未找到窗口」

确认窗口没有被最小化/遮挡。检查 `window_class` 和 `window_title` 参数。

### winnav 找到了错误的 Flutter 窗口（如 Hermes 自己）

→ 如实汇报 → 请用户关闭冲突窗口 → 重试。**不要自动重试，不要替用户猜。**

### winnav_init 报 1400（窗口句柄失效）

Flutter 重启后旧句柄失效。重试一次即可。连续 3 次失败 → 见 `references/winnav-troubleshooting.md` 执行完整恢复。

### 点崩溃后 NDJSON 才写到一半

NDJSON 在 `flutter run` 关闭后写全。用 `process(kill)` 杀掉 flutter 进程确保日志完整。

### 上一次的 NDJSON 日志被覆盖了

暂停诊断时先读出 NDJSON 再跑 engine。

### 需要先跑 Module 0 的数据准备

服务器端数据变更在 ECS 上做。做完后需要重新 `flutter run`。

---

## 推进日志

| 轮次 | 模块 | 走查进度 | ❌ 数 | 已修复 | 时间 |
|:----:|:----:|:--------:|:----:|:------:|:----:|
| — | — | — | — | — | — |

---

> **文件版本：** v3.2 · 五步闭环 · ecs_query.py verify → page · 状态检查点 · 2026-07-13
> **替代旧版：** v3.1（四步闭环 + 全量 dump 模式）
