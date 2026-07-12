# 章鱼智学 · 运行时审计流程手册

> 对应 Hermes skill：`runtime-verification`
> 对应审计引擎模块：⑫（运行态审计日志验证 + R12 模式分析）+ nav_engine（自动走查）+ vision_report（视觉交叉验证）
> 版本：2.1 | 最后更新：2026-07-12

**R（纯 NDJSON）：** `python docs/auto-audit/audit_engine.py D:\\Hermes\\zhangyuzhixue_app_v2 --type R`

**交互式 CLI 走查：**
```bash
# 每条命令独立执行，agent 看结果后即时决策
python nav_engine/walker.py init <workspace>        # 初始化→hwnd
python nav_engine/walker.py snap <hwnd> [label]    # 截图+OCR→列出文字
python nav_engine/walker.py click <hwnd> <文字>     # OCR定位→点击
python nav_engine/walker.py tab <hwnd> <0-3>       # 点底部Tab
python nav_engine/walker.py back <hwnd>            # 点返回
```

---

运行时审计检查的是 **app 实际跑起来之后的数据和画面**，与静态审计（project-owner-acceptance）互补。静态审计看代码对不对，运行态审计看数据和画面有没有问题。

---

## 一、一句话流程

> **你启动 app → agent 逐页交互式 CLI 走查（截图→OCR→决策→点击→循环）→ R 断言 + Vision 交叉验证 → 合并报告**

你只需启动 app，走查由 agent 通过 CLI 命令逐条完成，每一步都截图确认。无预编排、无死序列，每页看到什么点什么是可控的。vs 旧版全自动模式（REGISTRY 驱动，已删除）的优势：能处理滑动、空态跳过、异常时即时调整。

---

## 二、前置条件

### 2.1 测试账号（已有）

```
用户名: test_audit
密码:   test123
```

### 2.2 环境要求

| 项目 | 要求 |
|:----|:----:|
| 桌面 | 不锁屏，窗口不被遮挡 |
| DPI 缩放 | 建议 100%（影响 pyautogui 坐标精度） |
| Python 包 | `pip install -r docs/auto-audit/nav_engine/requirements.txt` |
| NDJSON 日志 | `%TEMP%/zhangyuzhixue_audit.ndjson`（AUDIT_MODE 自动写入）|

### 2.3 截图位置

截图自动保存至 `docs/auto-audit/screenshots/{日期}/`。命名规则：

```
{page}_{dimension}_{描述}.png
  例: index_V2_pendingCount.png
      solve-choice_I1_after10s.png
      login_stress_click10x.png
```

每次审计开始前自动清理 7 天前的旧截图。

---

## 三、完整流程（交互式 CLI 走查 + 分析）

### Step 1 — 启动带审计的 app

**👤 你手动做：**

```bash
cd D:\Hermes\zhangyuzhixue_app_v2\flutter_app
flutter run --dart-define=AUDIT_MODE=true
```

确认出现 `✓ Built build\windows\x64\runner\Debug\flutter_app.exe` 后，不要关闭终端，**去做别的事**。

---

### Step 2 — 交互式 CLI 走查（agent 逐页决策）

**🤖 对 agent 说：**

> 执行运行时审计走查，项目目录"..."

agent 执行以下循环：

```bash
# ① 初始化
python nav_engine/walker.py init D:\Hermes\zhangyuzhixue_app_v2    → 返回 HWND

# ② 截图+OCR，看到当前页面文字
python nav_engine/walker.py snap <hwnd> "首页"

# ③ 决策：看到"自主选题"→ 点它
python nav_engine/walker.py click <hwnd> 自主选题

# ④ 确认结果
python nav_engine/walker.py snap <hwnd> "选题页"

# ⑤ 循环...直到全部页面走完
```

**走查顺序建议（35 页 G1-G6）：**

| 分组 | 覆盖页面 | 入口 |
|------|---------|------|
| **G1** | 首页、推荐页 | 启动即见 / Tab 推荐 |
| **G2** | 组卷首页 → 自主选题/智能组卷/发现组卷/收藏/组卷历史 → 试卷预览/其它答案/答题卡 | Tab 组卷 |
| **G3** | 解题选择/填空/步骤/评分/解题地图 | 从组卷进入解题 |
| **G4** | 讲义课程 → 章节 → 内容 | 首页→讲义 |
| **G5** | 作业列表 → 详情 | 首页→作业 |
| **G6** | 个人资料 → 编辑/统计/成就/等级/积分/做题历史/学习偏好/同步状态/关于 | Tab 我的 |

**每页操作模式：**
```
snap → 看到按钮列表 → click/tab/back → snap 确认页面变化 → 记录 → 继续
```

---

### Step 3 — 并行分析（~3min）

走查完成后，两件事并行执行：

| 任务 | 方法 | 耗时 |
|:----|:----|:----:|
| **R** NDJSON 断言 | `audit_engine.py --type R`（R12.1-R12.6） | ~30s |
| **V** 视觉分析 | `delegate_task` 分 3 个子 agent 并行 vision_analyze | ~3min |

Vision 逐页检查 4 个维度（V1-V4）：

| 维度 | 查什么 | Vision 提示词方向 |
|:----:|:-------|:-----------------:|
| **V1** 布局完整性 | 元素是否可见、有无重叠/溢出/白屏 | 对照 HTML 原型描述逐项核对 |
| **V2** 数据正确性 | 提取屏幕数字 vs NDJSON 断言值做交叉验证 | "提取待办计数：___" |
| **V3** 导航可达 | 底部 Tab、列表项点击确有反应 | 点击后截图对比 |
| **V4** 空/错误态 | 无数据时占位符/重试按钮是否存在 | 数据为空时有提示而非白屏 |

#### Phase 3 — 合并报告（~10s）

```
vision_report/merge_reports.py:
  按分组 G1-G6 合并 R 断言 + V 视觉结果
  产出最终报告
```

---

### Step 3b — 纯 R 模式（无屏/无截图回退）

如果环境不支持截图（CI/SSH/无桌面），或已有旧 NDJSON 文件：

```bash
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R
```

此时不走查、不截图、无 vision 交叉验证，纯 NDJSON 数据断言。~30s 出报告。

---

## 四、报告示例

```
══════ 章鱼智学 · 合并审计报告 (R + V) ══════

### 分组概要
  G1 核心导航:        ✅ R=通过  V=通过
  G2 组卷/试题浏览:    ⚠️ R=1个CERTAIN V=1个WARNING
  G3 解题流程:        ❌ R=3个CERTAIN V=1个FAIL（白屏）
  G4 讲义:            ✅ R=通过  V=通过
  G5 作业:            ✅ R=通过  V=通过
  G6 个人中心:        ⚠️ R=1个SUSPICIOUS V=通过

### CERTAIN ❌
  ❌ [G3] 运行时错误: LectureCoursesPage._load → SQL 错误
  ❌ [G3] SolveChoicePage 截图: 白屏（app 崩溃）
  ❌ [G2] DAO 查询返回 0 行: ProgressDao 870 次

### V1-V4 视觉检查
  G3 solve_choice_V1:     ❌ 白屏 — 应用已崩溃
  G6 index_V2_pending:    ⚠️ NDJSON=4 但截图显示"0 项"

### 截图
  docs/auto-audit/screenshots/2026-07-12/
```

---

## 五、VR 阶段 — 复杂交互审计

> 仅 RV 模式下执行。以下交互需要用户操作序列，pyautogui 自动模拟。

### I1. 冷却计时器（选填题）

| 检查点 | 方法 |
|--------|------|
| 进入后按钮禁用 | 截图检查提交按钮为灰色 + 倒计时文字 |
| 倒计时文字正确 | 截图读文字："⏳ 还剩 N 秒可提交"（N=10→0）|
| 倒计时结束恢复 | 等 10s 后截图，按钮恢复可点击 |
| 多次进入重置 | 返回再进，截图确认每次从 10s 开始 |

### I2. 冷却计时器（步骤题）

| 检查点 | 方法 |
|--------|------|
| 展开箭头初始状态 | 截图确认 ▶ 按钮灰色 + "⏳ 还剩 5 秒" |
| 倒计时结束恢复 | 等 5s 后按钮可点击，内容展开 |
| 反馈按钮出现 | 展开后有"全对/过程对计算错/不会"三个按钮 |

### I3. 选项选择与提交（选择题）

| 检查点 | 方法 |
|--------|------|
| 点击高亮 | 点击 A，截图确认 A 高亮、其他恢复 |
| 提交后正确显示 | 倒计时结束→提交，截图确认 ✅/❌ + 解析展开 |
| 已完成横幅 | "🎉 已完成" 横幅可见 |
| 后续按钮 | 截图确认 [下一题 →] [⭐ 评分] 存在 |

### I4. 解题地图交互

| 检查点 | 方法 |
|--------|------|
| 首次进入 | "准备开始答题" 欢迎页 + "开始答题" 按钮 |
| 多步骤树形 | 走完 1 步后截图，地图上显示完成节点 |
| 多作答切换 | 切换作答次数，内容随切换更新 |
| 回顾模式 | "📋 回顾模式 · 只读浏览" 横幅 |

### I5. 评分与反馈

| 检查点 | 方法 |
|--------|------|
| 入口 | 从解题页点击"⭐ 评分"跳转到评分页 |
| 提交 | 选择一个评分项，提交成功 |
| 复访修改 | 回到已评分题目，评分可修改 |

### I1-I5 执行策略

- 从属于 G3（解题流程），只在审计解题页面时执行
- 每个检查项有独立 PASS/FAIL 标记
- 截图命名统一用 `{page}_I{序号}_{检查点}.png`

---

## 六、Phase 3 — 边界/压力审计

> 仅 RV 模式下执行。完成主流程后可选执行。

### 6.1 快速连续点击

连续点击同一按钮 10 次（间隔 0.15s），检查有无崩溃或重复提交。

### 6.2 窗口缩放

| 步骤 | 操作 |
|:----:|------|
| 缩到极小 | `MoveWindow(800, 600)` → 截图 |
| 最大化 | `ShowWindow(SW_MAXIMIZE)` → 截图 |
| 恢复 | `ShowWindow(SW_RESTORE) + MoveWindow(0,0,390,844)` → 截图 |

### 6.3 焦点切换

`Alt+Tab` 切走 → 等 2s → `Alt+Tab` 切回 → 截图检查画面是否正常。

### 6.4 文件选择器取消

触发文件选择器 → 按 `Esc` 取消 → 截图检查返回后画面是否正常。

---

## 七、引擎 12 项检查速览

| # | 查什么 | 级别 | 能查出什么问题 |
|---|-------|:----:|--------------|
| 1 | 页面覆盖 | LIKELY | 35 页实测覆盖率 |
| 2 | 字段是否为 null | CERTAIN | pendingCount 未加载 |
| 3 | 等级文字是否硬编码 | SUSPICIOUS | "Lv.5" 写死 |
| 4 | 跨页数据一致 | SUSPICIOUS | 首页≠作业页 |
| 5 | DAO 是否 0 行 | CERTAIN | assets.db 空表 |
| 6 | 服务端 vs 客户端对比 | CERTAIN | 799 vs 0 |
| 7 | 运行时错误 | CERTAIN | catch 块异常 |
| 8 | API 4xx/5xx | SUSPICIOUS | 端点错误 |
| 9 | **冷启动时序 (R12.1)** | CERTAIN | ensureOpen 前调用 |
| 10 | **DAO N+1 (R12.2)** | SUSPICIOUS | 798 次逐一查询 |
| 11 | **API 注入 (R12.3)** | CERTAIN | ApiClient 未注入 |
| 12 | **Logger 覆盖 (R12.5)** | CERTAIN/LIKELY | 35 页 vs 实际 |

---

## 八、常见问题

### Q: agent 说"未找到窗口"

确认 app 已在终端运行并且窗口可见。不要最小化。

### Q: vision 误判

降低提示词中样式要求，关注功能完整性。误判率高于 20% 时暂时跳过 V 阶段，只跑 R。

### Q: 可以只跑 R 吗？

可以。`audit_engine.py --type R` 不需要截图，只需要 NDJSON 日志存在即可。~30s 出报告。

### Q: 窗口黑屏

确认窗口没有被遮挡、最小化。检查 `win32gui.SetForegroundWindow` 是否成功。
