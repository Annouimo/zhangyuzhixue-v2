# 章鱼智学 · 运行时审计流程手册

> **版本：** v3.0 | **最后更新：** 2026-07-12
> **对应 Skill：** `runtime-verification`
> **代替：** 旧版全量走查→R→Vision 模式（已废弃）

---

## 核心理念：三步循环，走一段修一段

不再是一次性跑完 35 页再出报告。而是**走查→诊断→修复 循环往复**，直到 74 项排查清单全部 ✅。

```
┌──────────────────────────────────────────────────┐
│ ① 用 winnav 逐项走查模块（操作工具组）           │
│    遇到问题记录，遇到崩溃立即暂停                  │
│         ↓                                        │
│ ② 用 NDJSON + engine 诊断根因（排查工具组）       │
│    找到根源，不到表面                                │
│         ↓                                        │
│ ③ 用 fix-batch-workflow 修复（修复工具组）         │
│    方案→审批→执行→验证→提交                          │
│         ↓                                        │
│ ④ 重新 flutter run → 回到① 验证修复 + 继续走查    │
└──────────────────────────────────────────────────┘
```

### 三组工具

| 组别 | 工具 | 角色 |
|:----:|------|:----:|
| 🖱️ **操作** | winnav MCP Server（5 个工具） | 截图/OCR/点击/滚动/关闭，驱动 app 走查 |
| 🔍 **排查** | NDJSON + `audit_engine.py --type R` + server-driven 对比 | 读取日志，做 R12 模式分析，查根因 |
| 🔧 **修复** | `fix-batch-workflow` skill | 核实问题→出方案→等批准→执行→出报告 |

> **Vision 交叉验证：** 暂不启用。winnav 的 OCR 已覆盖视觉需求，NDJSON + server-driven 的数据比对比 AI 视觉更可靠（AI 视觉误判率 >20%）。下一阶段再引入。

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
| `winnav_click` | OCR 定位文字并点击 | `text` 必填，`exact` 默认 false（模糊匹配） |
| `winnav_scroll` | 按窗口高度百分比滚动 | `dy` 负值=向下，-1.0=向下一整屏 |
| `winnav_close` | 输出完整 JSON 操作日志 | 无参数，必须在每次走查结束时调用 |

**核心设计：** 所有坐标用百分比（窗口相对数据），不涉及像素。截图输出到 `%TEMP%/winnav/screenshots/{日期}/`，日志到 `%TEMP%/winnav/logs/`。

---

## 完整流程

### Step 0 — 前置准备（模块 0）

**👤 你在 ECS 上执行：**

- [ ] 构建题库数据：`python manage.py build_assets --test && python manage.py build_lectures --test`
- [ ] 生成邀请码：Admin → `/admin/system/tools/` → 数量 5、有效期 30 天
- [ ] 创建作业：Admin 中创建 2 份 HomeworkAssignment，assign 给 test_audit
- [ ] 创建公开组卷：创建 2 份试卷 → 设为公开
- [ ] 确认讲义数据：调 `GET /api/v1/lectures/courses/` 返回非空
- [ ] 确认 test_audit 账号存在：Admin 中查 User 表

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

# 4. 确认页面变化
winnav_snap(label="选题页")

# 5. 如果需要滚动
winnav_scroll(dy=-1.0)

# 6. 点底部 Tab
winnav_click(text="组卷")

# 7. 走查结束时输出操作日志
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

### Step 2 — 诊断：NDJSON + engine 查根因

暂停后，**不要猜测根因**，用数据说话：

```bash
# 2a. 跑 R 断言（~30s）
python docs/auto-audit/audit_engine.py D:\\Hermes\\zhangyuzhixue_app_v2 --type R
```

输出 CERTAIN / LIKELY / SUSPICIOUS 三级发现。

**扩展诊断手段：**

| 场景 | 做法 |
|:----|:-----|
| DAO 返回 0 行 | 用 server-driven 对比：`SELECT COUNT(*) FROM qbank_basequestion` vs NDJSON 中的 `QuestionDao.search.rowCount` |
| 页面崩溃 | 用 crash chain 分析：找最后一个 page 日志 → 找第一个 error → 统计 error 来源 → 构建时间线 |
| API 未调用 | 检查 `cat='api'` 条目数是否为 0（R12.3 — ApiClient 未注入） |
| 冷启动时序 | 检查 seq<10 内是否有 `ensureOpen`/`Bad state` 错误（R12.1） |
| 页面间卡住 | 检查两 page 间非 page 日志是否 ≥100 条（R12.4） |
| N+1 查询 | 检查同一 DAO 调用 ≥20 次且全 0 行（R12.2） |
| AuditLogger 覆盖 | 检查预期 35 页 vs 实际有 page 日志的页数（R12.5） |
| null vs 空串误报 | 检查 `vt='null'` 且 `val=''`（R12.6） |

**对于崩溃页面，标准诊断流程：**

```powershell
# 找最后一个 page 日志
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json | Where-Object cat -eq 'page' | Sort-Object seq -Descending | Select-Object -First 5

# 找第一个 error
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json | Where-Object { $_.seq -ge <last_page_seq> -and $_.cat -eq 'error' } | Select-Object -First 5

# 统计 error 来源和总量
Get-Content "$env:TEMP\zhangyuzhixue_audit.ndjson" | ConvertFrom-Json | Where-Object cat -eq 'error' | Group-Object src | Select-Object Name, Count | Sort-Object Count -Descending
```

**结果** 是一个根因明确的 ❌ 列表（已去重、已归类），进入下一阶段。

---

### Step 3 — 修复：fix-batch-workflow

按 `fix-batch-workflow` skill 执行：

**Phase 1 — 方案阶段（仅对话，不写文件）：**

1. 对每个 ❌ 核实：读代码、读设计文档、确认根因、搜索 git history 确认是否已有修复
2. 分解复合问题（一个 ❌ 可能对应多个子问题）
3. 标注修复类型：`code-only` / `design-sync` / `api-dependent` / `infrastructure`
4. 输出结构化修改方案（问题→文件→改动→设计文档更新）
5. **等待你批准**

**Phase 2 — 执行阶段（你批准后）：**

1. 执行所有修复（代码 + 设计文档同步更新）
2. 跑测试：`dart analyze` + `flutter test`（Flutter 端） / `pytest` + `flake8`（server 端）
3. 精确 `git add`（只添加本次修复的文件）
4. 提交
5. 出状态报告（对话形式）

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

---

## 推进日志（每次循环更新）

| 轮次 | 模块 | 走查进度 | ❌ 数 | 已修复 | 时间 |
|:----:|:----:|:--------:|:----:|:------:|:----:|
| — | — | — | — | — | — |

---

> **文件版本：** v3.0 · 三步循环模式 · 2026-07-12
> **替代旧版：** 全量走查→R→Vision 模式（v2.1 及之前）
