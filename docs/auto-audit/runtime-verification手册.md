# 章鱼智学 · 运行时审计流程手册

> **版本：** v3.1 | **最后更新：** 2026-07-13
> **对应 Skill：** `runtime-verification`
> **代替：** 旧版全量走查→R→Vision 模式（已废弃）

---

## 🚀 快速启动：一键开走

复制以下任意一句到 Hermes 对话中即可开始走查：

```
🤖 对 agent 说：/skill runtime-verification 执行 模块0（前置准备），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块1（登录/注册/引导），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块2（首页+讲义），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块3（解题模式），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块4（推荐），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块5（组卷），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块6（作业），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块7（统计），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块8（个人中心），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
🤖 对 agent 说：/skill runtime-verification 执行 模块9（辅助系统），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
```

> **注意：** 模块有依赖顺序（如模块 7 需要先做模块 3 的题），建议从 0→1→2→... 依次执行。遇到崩溃会自动暂停诊断，修完再继续。

---

## 核心理念：四步闭环，走一段修一段

不再是一次性跑完 35 页再出报告。而是**走查→诊断+核实→方案执行→验证 循环往复**，直到 74 项排查清单全部 ✅。

```
┌──────────────────────────────────────────────────┐
│ ① 用 winnav 逐项走查模块                          │
│    遇到问题记录，遇到崩溃立即暂停                  │
│         ↓                                        │
│ ② NDJSON 诊断 + 核实（代码只读一遍）               │
│    R断言 → 读代码 → 查git history → 对照设计文档   │
│    → 标注修复类型 → 分解复合问题 → 搜影响点       │
│         ↓                                        │
│ ③ 方案与执行                                      │
│    出方案（不重读代码）→ 等批准 → 改代码+文档      │
│    → 测试 → 精确提交 → 状态报告                    │
│         ↓                                        │
│ ④ 重新 flutter run → 回到① 验证修复 + 继续走查    │
└──────────────────────────────────────────────────┘
```

### 两组工具

| 组别 | 工具 | 角色 |
|:----:|------|:----:|
| 🖱️ **操作** | winnav MCP Server（5 个工具） | 截图/OCR/点击/滚动/关闭，驱动 app 走查 |
| 🔍 **排查+修复** | NDJSON + engine + 内建核实+方案+执行 | 诊断根因→核实→出方案→执行→提交（完整闭环） |

> **Vision 交叉验证：** 暂不启用。winnav 的 OCR 已覆盖视觉需求，NDJSON + server-driven 的数据对比 AI 视觉更可靠（AI 视觉误判率 >20%）。下一阶段再引入。
> **不再委托 fix-batch-workflow：** 它的核实步骤已合并到 Phase 2（避免重复读代码），方案与执行步骤已合并到 Phase 3。fix-batch-workflow 仍保留供其他途径发现问题时使用。

---

## 前置条件

### 环境

| 项目 | 要求 |
|:----|:----:|
| 桌面 | 不锁屏，窗口不被遮挡 |
| 窗口 | Flutter app 已通过 `flutter run` 启动并登录 |
| 其它 | 关闭/最小化 Hermes 桌面客户端等可能冲突的 Flutter 窗口 |
| 账号 | `test_audit` / `test123`（服务器端预创建，见模块 0） |
| NDJSON | `flutter run --dart-define=AUDIT_MODE=true` 自动写入 `%TEMP%/zhangyuzhixue_audit.ndjson` |
| winnav | `hermes mcp list` 确认 `winnav` 已注册并启用 |

### winnav MCP 快速参考

| 工具 | 用途 | 关键参数 |
|:----:|------|---------|
| `winnav_init` | 找窗口+置前+截图+OCR | `window_class` (默认 `FLUTTER_RUNNER_WIN32_WINDOW`), `window_title` (默认 `flutter_app`), `target_w`/`target_h` (默认 None=不 resize) |
| `winnav_snap` | 截图+OCR（~0.6s） | `label` 可选，用于命名截图 |
| `winnav_click` | OCR 定位文字并点击 | `text` 必填，`exact` 默认 false（模糊匹配）；`y_range=[min, max]` 可选，过滤 y 百分比范围，如 `[0.9, 1.0]` 只匹配底部 10% |
| `winnav_click_at` | 按百分比坐标点击（绕过 Icon 盲区） | `x_pct`, `y_pct`: 0.0~1.0 窗口客户区百分比 |
| `winnav_scroll` | 按窗口高度百分比滚动 | `dy` 负值=向下，-1.0=向下一整屏 |
| `winnav_close` | 输出完整 JSON 操作日志 | 无参数，必须在每次走查结束时调用 |

**核心设计：** 所有坐标用百分比（窗口相对数据），不涉及像素。截图输出到 `%TEMP%/winnav/screenshots/{日期}/`，日志到 `%TEMP%/winnav/logs/`。

---

## 完整流程

### Step 0 — 前置准备（模块 0）

**👤 你在 ECS 上执行：**

- [x] 构建题库数据：`python scripts/build_assets.py --test && python scripts/build_lectures.py --test`
- [x] 生成邀请码：Admin → `/admin/system/tools/` → 数量 5、有效期 30 天
- [x] 创建作业：Admin 中创建 2 份 HomeworkAssignment，assign 给 test_audit
- [x] 创建公开组卷：创建 2 份试卷 → 设为公开
- [x] 确认讲义数据：调 `GET /api/v1/lectures/courses/` 返回非空
- [x] 确认 test_audit 账号存在：Admin 中查 User 表

**👤 你本地执行：**

```bash
cd D:\Hermes\zhangyuzhixue_app_v2\flutter_app
flutter run --dart-define=AUDIT_MODE=true
```

确认 `✓ Built build\windows\x64\runner\Debug\flutter_app.exe` 后，app 窗口出现。不要关闭终端。

---

### Step 1 — 走查：winnav 逐项排查

**🤖 agent 执行：** 按 `docs/auto-audit/基础功能排查清单.md` 中定义的**模块 1 起**逐项走查。

标准操作模式：

```python
# 1. 初始化（定位窗口）
winnav_init(window_class="FLUTTER_RUNNER_WIN32_WINDOW")

# 2. 截图+OCR，看当前页
winnav_snap(label="首页")

# 3. 决策：看到"自主选题"→ 点它
winnav_click(text="自主选题")

# 4. 同一文字在顶部和底部同时出现（如 AppBar "←" vs pager "←"）
#    用 y_range 过滤底部区域
winnav_click(text="←", y_range=[0.9, 1.0])

# 5. 按钮是 Material Icon（OCR 不可见）→ 坐标点击
winnav_click_at(x_pct=0.05, y_pct=0.96)  # 翻页栏左箭头

# 6. 如果需要滚动
winnav_scroll(dy=-1.0)

# 7. 点底部 Tab
winnav_click(text="组卷")

# 8. 走查结束时输出操作日志
winnav_close()
```

**走查顺序：** 模块 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

### 暂停规则

| 条件 | 动作 |
|:----|:----:|
| **模块完成**（该模块所有项均已走查，无论有几项 ❌） | ✅ **暂停**，进入诊断阶段 |
| **遇到崩溃/白屏**（app 不可交互） | 🔴 **立即暂停**，因为后续页面无法继续走查 |
| **单个模块累计 ≥8 个 ❌** | ⏸ **提前暂停**，batch 太大时影响诊断质量 |
| 某个 ❌ 是**数据异常**（如待办显示0）但页面可继续操作 | ➡ **记入清单，继续走**，不暂停 |
| 某个 ❌ 是 **winnav 找不到按钮** | ➡ **记入清单，尝试用其他路径绕过**，不暂停 |

---

### Step 2 — 诊断 + 核实（代码只读一遍）

暂停后执行以下流程。**Phase 2 既是诊断也是核实，代码只读一遍，Phase 3 不再重新打开文件。**

#### 2a. 跑 R 断言

```bash
# 2a. 跑 R 断言（~30s）
python docs/auto-audit/audit_engine.py D:\\Hermes\\zhangyuzhixue_app_v2 --type R
```

输出 CERTAIN / LIKELY / SUSPICIOUS 三级发现。

**扩展诊断手段：**

| 场景 | 做法 |
|:----|:-----|
| DAO 返回 0 行 | 用 server-driven 对比：`python docs/auto-audit/ecs_query.py count questions` vs NDJSON 中的 `QuestionDao.search.rowCount` |
| 页面崩溃 | 用 crash chain 分析：找最后一个 page 日志 → 找第一个 error → 统计 error 来源 → 构建时间线 |
| API 未调用 | 检查 `cat='api'` 条目数是否为 0（R12.3 — ApiClient 未注入） |
| 冷启动时序 | 检查 seq<10 内是否有 `ensureOpen`/`Bad state` 错误（R12.1） |
| 页面间卡住 | 检查两 page 间非 page 日志是否 ≥100 条（R12.4） |
| N+1 查询 | 检查同一 DAO 调用 ≥20 次且全 0 行（R12.2） |
| AuditLogger 覆盖 | 检查预期 35 页 vs 实际有 page 日志的页数（R12.5） |
| null vs 空串误报 | 检查 `vt='null'` 且 `val=''`（R12.6） |

#### 2a-ECS. 服务器端数据核实

当 ❌ 涉及**服务器持有状态**（签到/积分/进度/作业/课程）时，用 `ecs_query.py`（避免 SSH 引号地狱）快速查证：

```bash
# 一次检查所有关键指标
python docs/auto-audit/ecs_query.py health

# 查单表行数（支持别名：questions/courses/configs/users/homework）
python docs/auto-audit/ecs_query.py count questions

# 查用户详情
python docs/auto-audit/ecs_query.py check-user test_audit

# 任意 SQL
python docs/auto-audit/ecs_query.py sql "SELECT COUNT(*) FROM system_systemconfig"

# 查模型字段定义
python docs/auto-audit/ecs_query.py models Assignment
```

**输出标记：**
- `server-confirmed-bug` — 服务器有数据但客户端不匹配 → 客户端 bug
- `client-data-inconsistency` — 服务器有数据但客户端未同步 → 同步 bug
- `data-missing` — 服务器无此数据 → 旧版残余 / 从未生成

**对于崩溃页面，标准诊断流程：**

```powershell
# 找最后一个 page 日志
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json | Where-Object cat -eq 'page' | Sort-Object seq -Descending | Select-Object -First 5

# 找第一个 error
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json | Where-Object { $_.seq -ge <last_page_seq> -and $_.cat -eq 'error' } | Select-Object -First 5

# 统计 error 来源和总量
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json | Where-Object cat -eq 'error' | Group-Object src | Select-Object Name, Count | Sort-Object Count -Descending
```

#### 2b. 读代码确认根因

打开 Phase 1 记录 ❌ 涉及的文件，确认根因在哪个函数/条件/Widget，**记录文件+行号**。

#### 2c. 查 git history

对每个 ❌ 跑 `git log --all --oneline --grep=<关键词>`。如发现已有提交涉及该问题：
- `git show <sha>` 读 diff — 确认修复是否完整（是否只修了一边）
- 标记结果：`already-fixed` / `partially-fixed` / `needs-fix`

#### 2d. 读设计文档对照

对每个 ❌ 打开相关设计文档阅读：

- 代码与设计文档不一致时：**确认哪端更正确**
  - 代码更正确 → 标记"需更新设计文档"
  - 设计更正确 → 代码是 bug，正常修
- 跨文档交叉检查：HTML 原型、API 设计文档、数据库结构文档之间是否自洽？发现不一致时强制停止，等你拍板。

#### 2e. 标注修复类型

| 类型 | 含义 |
|:----:|------|
| `code-only` | 纯代码改动 |
| `design-sync` | 需要同步设计文档和代码 |
| `api-dependent` | 需要服务端新增/修改 API |
| `infrastructure` | 构建工具链/平台配置问题（排除） |
| `data-exists-but-not-wired` | 数据在 DAO/Repository 存在但 UI 没消费 |
| `data-missing` | 数据根本不存在 |

#### 2f. 分解复合问题 + 搜影响点

一个 ❌ 对应多个根因时分解为子问题。涉及字段/端点/表名等命名概念时，`grep -rn '<概念>'` 搜全项目，列消费者。

#### 2g. 输出诊断结果

已核实+已分类+已分解的 ❌ 列表。**这个列表直接进入 Phase 3，不需要重新核实。**

|---

### Step 3 — 方案与执行

不再委托外部 skill。Phase 2 已完成核实（代码已读过），Phase 3 直接出方案。

**Phase 3a — 出方案（仅对话，不写文件）**

基于 Phase 2 的输出，按以下格式出修改方案：

```
## 修改方案

| # | 问题 | 涉及文件 | 设计文档更新 | 类型 | 说明 |
|---|------|---------|:----------:|:----:|------|
| 1 | ... | server/courses/views.py, flutter_app/... | ✅ API设计.md | design-sync | 代码>文档,需同步 |
| 2 | ... | flutter_app/lib/pages/xxx.dart | — 无需修改 | code-only | 纯 UI 修复 |
| 3 | ... | — | — | false-alarm | git history:已修复 |
```

**规则：**
- 不要因为"更简单"就提交简化方案。简单不是决策依据。
- 每条修复必须完整，不含 stub / TODO。
- 设计文档更新列每有一个 ✅，修改计划中必须对应一个 docs/ 行。
- 涉及命名概念时，把 Phase 2f 搜到的所有消费点一并列在方案中。

**Phase 3b — 等批准**

出方案后停止。不写文件、不执行。等你说了"执行吧"后再进入 Phase 3c。

**Phase 3c — 执行（你批准后）**

1. 按方案列表一次执行所有改动
2. 设计文档与代码同步更新
3. `git add` 只加本次修复的文件（精确路径）
4. `git diff --cached --stat` 检查 staging 区

**Phase 3d — 测试**

```
Flutter:  dart analyze && flutter test
Server:   pytest server/scripts/tests/ && flake8 --config .flake8
```

测试失败则修。不能宣布"部分成功"。

**Phase 3e — 提交**

```bash
git commit -m "fix: N项问题修复 — <摘要>"
```

**Phase 3f — 状态报告**

对话形式输出（不写文件），包含：
- 总览（计划 N 项，已修复 M 项）
- 逐项明细表（# → 问题 → DONE/FAIL）
- 测试结果
- 提交 hash

---

### Step 4 — 验证 + 继续

1. **👤 你：** 重新 `flutter run --dart-define=AUDIT_MODE=true`
2. **🤖 agent：** winnav 回退到上次暂停的模块，验证已修复的 ❌ 是否通过，然后继续走查该模块未走的项
3. 循环回到 Step 1

---

## 走查范围 + 模块进度表

见 `docs/auto-audit/基础功能排查清单.md` — 该清单为权威来源。共 10 个模块（0-9），74 个检查项，36 个页面。

### 模块依赖关系

```
模块 0（前置）→ 必须最先完成
模块 1（登录/注册）→ 需要模块 0 完成
模块 2（首页/讲义）→ 需要模块 1 登录成功
模块 3（解题）     → 需要模块 1 登录成功
模块 4（推荐）     → 需要模块 1 登录成功
模块 5（组卷）     → 需要模块 1 登录成功
模块 6（作业）     → 需要模块 2 走通首页「待办作业」
模块 7（统计）     → 需要模块 3 先做题积累数据 + 数据同步到服务端
模块 8（个人中心） → 需要模块 1 登录成功
模块 9（辅助系统） → 需要模块 3 先做题积累数据（同步队列才有记录）
```

### 建议走查顺序

```
0 → 1 → 2 → [3 → 6] 并行 → [4 → 5] 并行 → 7 → 8 → 9
                ↑______________________|
              模块3做完后才有模块7的数据
```

---

## NDJSON 审计日志参考

### 格式

```json
{
  "seq": 1,
  "ts": "2026-07-12T10:30:00.000000",
  "cat": "page",        // page | dao | prefs | sync | api | _meta | error
  "src": "IndexPage",
  "key": "pendingCount",
  "val": "4",
  "vt": "int"           // int | str | bool | double | null
}
```

### 5 个注入点

| cat | 注入位置 |
|:---:|---------|
| `page` | 每个 `_page.dart` 的 setState 数据加载完成后 |
| `dao` | 每个 DAO 方法 return 前 |
| `prefs` | `AppPrefs` 每个 getter 中 |
| `sync` | SyncManager/UpdateManager/SyncPusher 关键操作后 |
| `api` | ApiClient 拦截器响应后 |

### R12 运行时模式分析（引擎自动检查）

| 子规则 | 查什么 | 级别 |
|:-----:|--------|:----:|
| R12.1 | 冷启动前 10 条内是否有 `ensureOpen`/`Bad state` 等时序错误 | CERTAIN |
| R12.2 | 同一 DAO 被调用 ≥20 次且全部返回 0 行 → N+1 查询 | SUSPICIOUS |
| R12.3 | page 日志存在但零 API 条目 → ApiClient 未注入 AuditLogger | CERTAIN |
| R12.4 | 两页面间 ≥100 条非 page 日志 → 可能卡住 | LIKELY |
| R12.5 | 预期页面数 vs 实际有日志的页面数 → AuditLogger 注入完整性 | CERTAIN/LIKELY |
| R12.6 | `vt='null'` 但 `val=''` 的字段 → 空字符串被误报为 null | SUSPICIOUS |

---

## 常见问题

### app 已启动但 winnav_init 返回「未找到窗口」

确认窗口没有被最小化/遮挡。检查 `winnav_init` 的 `window_class` 和 `window_title` 参数是否匹配实际窗口。

### winnav 找到了错误的 Flutter 窗口（如 Hermes 自己）

表现：OCR 文字不是章鱼智学的页面内容（如读到「对话历史」「工作空间」）。

**处理：** 如实汇报 → 请用户关闭/最小化冲突窗口 → 重试。**不要自动重试，不要替用户猜。**

排查方法：
```powershell
Get-WmiObject Win32_Process -Filter "Name='flutter_app.exe'" | Select-Object ProcessId,CommandLine
```

### winnav_click 找不到按钮

winnav 会输出 OCR 实际读到的前 12 个文字，参考它们调整目标文字。支持模糊匹配（`exact=False`，默认），可以输入子串。

### 点崩溃后 NDJSON 才写到一半

NDJSON 文件在 `flutter run` 关闭后会写全。如果 app 完全卡死，可能需要关闭 app 窗口来触发日志写入。用 `process(kill)` 杀掉 flutter 进程确保日志完整。

### 上一次的 NDJSON 日志被覆盖了

每次 `flutter run` 覆盖 `%TEMP%/zhangyuzhixue_audit.ndjson`。需要在覆盖前备份，或者每次暂停诊断时立即读入再跑下一步。

### 需要先跑 Module 0 的数据准备

服务器端数据变更（构建题库、创建邀请码等）必须在 ECS 上执行。做完后需要**重新 `flutter run`** 才能取到新数据。

### winnav 滚动距离太短（旧版本已知问题）

问题表现：`winnav_scroll(dy=-1.0)` 期望滚一屏，实际只滚了极小距离。
**根因：** pyautogui.scroll(clicks) 的 `clicks` 参数会直接传入 `mouse_event` 的 `dwData`，而 Windows 的 `dwData` 单位是 WHEEL_DELTA(120)。旧代码 `scroll(notches)` 传的是物理齿数（如 31），实际发送 `dwData=31` 相当于 31/120 = 0.26 个滚轮齿。
**修复：** 2026-07-13 已改为 `scroll(notches * 120)`，重启 winnav MCP 后生效。新会话正常。`winnav_at` 和 `y_range` 功能需要同时更新。

---

## 推进日志（每次循环更新）

| 轮次 | 模块 | 走查进度 | ❌ 数 | 已修复 | 时间 |
|:----:|:----:|:--------:|:----:|:------:|:----:|
| — | — | — | — | — | — |
| 1 | 2（首页+讲义） | 2.1~2.7 已走查，2.8 待验证 | 0 | winnav 增强(3项)+ecs_query 脚本 | 2026-07-13 |

---

> **文件版本：** v3.1 · 增强 winnav + ecs_query · 2026-07-13
> **替代旧版：** 全量走查→R→Vision 模式（v2.1 及之前）
> **工具变更：** `winnav_click` 新增 `y_range` 参数、新增 `winnav_click_at` 坐标点击、`winnav_scroll` 修复 WHEEL_DELTA 乘数、`ecs_query.py` 替代手动 SSH
