# 章鱼智学 · 视觉理解审计手册（Type V — RV 扩展模式）

> 版本: 0.3.1 — 已整合为 RV 模式的 Vision 组件（2026-07-12）
> 相关技能: `runtime-verification`
> 相关审计类型: **V 不再独立运行，作为 RV（R + Vision）的一部分**
> 独立入口：❌ 已取消。所有 Vision 检查通过 `--type RV` 或 skill 的“全自动运行时审计”触发。

---

## Skill 命令（1 条）

```text
/skill runtime-verification 执行 RV — 全自动运行时审计（走查+NDJSON+Vision），项目目录"D:\Hermes\zhangyuzhixue_app_v2"
```

## 架构

```
RV 模式 = walker.py (自动走查) → audit_engine.py --type R (NDJSON断言) → vision_report/ (Vision + 合并)
                                                                                ↑
                                                                    visual-audit手册.md 描述此处
```

加载本 skill 后，直接发送以下消息即可执行对应模式：

```text
/skill visual-e2e-audit 执行全量审计 — 6 个 Group + 4 流程 + 5 交互 + 4 边界，项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行快速冒烟（Group G1） — 核心导航 3 页，项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行 Group G3 — 解题流程（含 I1-I5 复杂交互），项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行 Group G2+G6 — 组卷 + 个人中心，项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行快速冒烟并设置 fail-fast=3，项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行 Group G3 并设置 fail-fast=5，项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行增量审计 — 仅验证上次 FAIL 的问题是否修复（组: remaining），项目目录"D:\Hermes\zhangyuzhixue_app_v2"

/skill visual-e2e-audit 执行自定义组合 — Group G1,G4,G5，项目目录"D:\Hermes\zhangyuzhixue_app_v2"
```

## 一、背景与动机

### 1.1 痛点

现有审计体系（Type A-G 代码审计 + Type R 运行时审计）覆盖了以下维度：

- **代码存在性** — 文件/模型/端点是否存在
- **设计文档对齐** — 代码与设计文档逐字段比对
- **测试存在性** — 测试文件是否存在
- **运行时日志** — NDJSON 日志中的非空/计数/时序断言

**仍然存在的盲点（用户真实反馈）：**

> "自动化测试全绿，但真实使用效果很不好"

根本原因：WidgetTester 跑在隔离的内存环境中，**跳过了 Windows 真实渲染引擎、DLL 依赖、线程调度和桌面 DPI 缩放**。测试通过 ≠ 真实用户不遇到布局崩溃/显示错误。

### 1.2 解决思路

**Type V 视觉审计** 的核心理念：

> 代理 **不看代码**，只看屏幕截图（视觉），只动鼠标键盘（模拟），利用大模型的视觉理解能力判断画面是否"正常"。

```
Type A-G: 读代码 + 设计文档 → 检查"代码写没写"
Type R:   读 NDJSON 日志 → 检查"运行时有没有异常值"
Type V:   看截图 + 操作 App → 检查"看起来对不对"
```

### 1.3 与现有体系的关系

| 维度 | Type A-G | Type R | **Type V (新)** |
|------|:--------:|:------:|:--------------:|
| 布局溢出/重叠 | ❌ | ❌ | ✅ 截图可发现 |
| 硬编码显示值 | ⚠️ H6 人工 | ❌ | ✅ vision 能读出屏幕数字 |
| 运行时不崩溃 | ❌ | ✅ NDJSON | ✅ 真机运行就暴露 |
| 空状态占位符 | ❌ | ⚠️ 间接 | ✅ 截图可见 |
| 多窗口/焦点切换 | ❌ | ❌ | ✅ pyautogui 模拟 |
| 设计文档对齐 | ✅ | ❌ | ❌（非本类型目标） |
| 测试存在性 | ✅ | ❌ | ❌（非本类型目标） |

---

## 二、前置条件

### 2.1 工具链

| 工具 | 用途 | 来源 |
|------|------|------|
| `pyautogui` | 鼠标点击、键盘输入、拖拽 | `pip install pyautogui` |
| `mss` | 快速屏幕截图（比 pyautogui.screenshot 快 10x） | `pip install mss` |
| `opencv-python` | 模板匹配（辅助定位按钮），pHash 图像对比 | `pip install opencv-python` |
| `Pillow` | 图像处理（缩放/裁剪） | 已随 pyautogui 安装 |
| `win32gui` / `win32con` | 窗口管理（查找/置前/调整大小） | 已预装（`pywin32`） |
| **辅助视觉模型** | 截图分析、布局判断 | `auxiliary.vision` 已配：alibaba/qwen3.7-plus |

### 2.2 环境要求

- **用户先在终端手动运行 `flutter run -d windows`** — 确认显示 `✓ Built build\windows\x64\runner\Debug\flutter_app.exe` 和 VM Service 地址后再调用 skill。agent 会先检查进程是否存在。
- **桌面不能锁屏** — pyautogui 依赖活跃的桌面会话（可考虑 RDP/虚拟机）
- **测试用户已登录** — 视觉审计需要已登录状态才能遍历大部分页面（也可从登录页开始全流程审计）
- **DPI 缩放固定** — 建议设置为 100%，避免坐标偏移
- **测试数据准备** — assets.db / user.db 中包含足够的数据用于显示验证

### 2.3 注意事项

- pyautogui 是前台工具，会移动真实鼠标。审计运行时勿触摸鼠标键盘。
- 管理员权限不是必需的，但如果应用启动需要 UAC 提权，则需要以管理员身份运行 Hermes/Python。
- 窗口最小化或被遮挡会导致截图不准确。代理会在每次操作前确保目标窗口置前。
- **不要用 Hermes 的 `terminal(background=true)` 或 `subprocess.Popen` 启动 `flutter run`** — 没有 PTY 交互终端，`flutter run` 会立即退出（exit code 1，输出乱码）。必须由用户在**个人终端**手动执行。

---

## 三、分组策略（解决"页面太多测不完"问题）

### 3.1 预定义分组

页面按使用场景分为 6 个 Group，每个 Group 可独立执行：

| Group | 名称 | 包含页面 | 预估耗时 | 适合场景 |
|:-----:|------|---------|:--------:|---------|
| **G1** | 核心导航 | index, login, register, main_shell (tab 切换) | 2-3 min | 快速冒烟 |
| **G2** | 组卷/试题浏览 | exam_home, exam_pick, exam_auto, exam_explore, exam_quicklook, answer_sheet, exam_favorites, exam_history, exam_quicklook_other | 4-6 min | 试题库回归 |
| **G3** | 解题流程 | solve_choice, solve_fill, solve_step, solve_map, solve_rate | 6-10 min | 核心功能回归 |
| **G4** | 讲义 | lecture_courses, lecture_chapters, lecture_content | 2-3 min | 内容渲染回归 |
| **G5** | 作业 | homework_list, homework_detail | 2-3 min | 作业回归 |
| **G6** | 个人中心 | profile, profile_edit, preference_list, preference_edit, preference_welcome, achievement, level_detail, points, question_history, about, sync_queue | 5-8 min | 个人数据回归 |

### 3.2 三种执行模式

调用 skill 时通过参数 `--group` 指定：

```yaml
# 模式 A：全量审计（所有 Group）
--group=all

# 模式 B：分组审计
--group=G1        # 只测核心导航
--group=G1,G3,G6  # 自定义组合

# 模式 C：快速冒烟（只测 G1）
--group=smoke     # 等价于 G1

# 模式 D：问题驱动（发现 N 个问题后暂停）
--group=all --fail-fast=5
# 发现 5 个 FAIL 后自动暂停，输出已发现的半程报告
# 修复后再用 --group=remaining 继续未完成的页面
```

### 3.3 Fail-Fast 机制

当一个问题密集的页面连续产生多个 FAIL 时，继续测它的子页面没有意义。Fail-Fast 规则：

| 触发条件 | 行为 |
|---------|------|
| 累计 FAIL 数达到 `--fail-fast=N` | 暂停审计 → 输出半程报告 → 等用户决定继续还是先修 |
| 单个页面连续 3 个 FAIL | 跳过该页面的 V3/V4 子检查，进入下一页 |
| 应用崩溃（窗口消失） | 立即暂停，报告崩溃截图，等用户处理 |
| Phase 2 流程中任一步骤 FAIL | 该流程标记为 BLOCKED，剩余步骤跳过 |

---

## 四、工作流

### Phase 0 — 前期准备

#### Step 0.1：提取页面清单

从 HTML 原型目录读取完整的页面清单，建立预期：

```bash
# 原型文件位于 docs/04-UI/html/
# 36 个原型 .html 文件
# 对应 Flutter 端约 36 个 _page.dart
```

输出清单（记录每个页面的 HTML 原型路径 → Flutter page 路径 → 是否已实现）：

| 原型 | Flutter 页面 | 状态 |
|------|-------------|:----:|
| index.html | index_page.dart | ✅ |
| login.html | login_page.dart | ✅ |
| solve-choice.html | solve_choice_page.dart | ✅ |
| ... | ... | ... |

#### Step 0.2：提取每个页面的元素清单

对每个 HTML 原型，按布局区域提取所有 UI 元素（作为后续视觉断言的"预期清单"）：

| 页面 | 区域 | 元素 | 类型 |
|------|------|------|------|
| index.html | 欢迎语卡片 | 随机励志语 + "每天一句"标注 | text |
| index.html | 待办作业 | 计数 + "项未完成" | link |
| index.html | 签到行 | 连续签到天数 | text |
| index.html | 今日任务 | 题目数、正确数 | text |
| ... | ... | ... | ... |

#### Step 0.3：截图目录初始化

```
截图根目录: %TEMP%/zhangyuzhixue_audit_V/
                                                   (见 §六 命名/清理规则)
```

#### Step 0.4：确认应用已启动（或请用户启动）

Agent 首先检查 flutter_app 进程是否存在：

```python
import psutil
import time

proc_name = "flutter_app"
found = any(p.info["name"] == proc_name for p in psutil.process_iter(["name"]))

if not found:
    # 进程不存在 → 提示用户手动启动
    print("=" * 60)
    print("⚠️  Flutter 应用未运行")
    print("请在您的终端中执行：")
    print("  cd D:/Hermes/zhangyuzhixue_app_v2/flutter_app")
    print("  flutter run -d windows")
    print("确认出现 VM Service 地址后，回来继续。")
    print("=" * 60)
    # 等待用户确认
    input("按 Enter 继续...")

# 轮询等待窗口出现（最多 30s）
hwnd = None
for _ in range(30):
    time.sleep(1)
    # 尝试匹配窗口标题
    for p in psutil.process_iter(["name", "pid"]):
        if p.info["name"] == proc_name:
            hwnd = ...  # 通过 win32gui 获取窗口句柄
            if hwnd:
                break
    if hwnd:
        break

if not hwnd:
    raise RuntimeError("App window not found after 30s — 可能崩溃或尚未启动")
```

关键变更：
1. ❌ 不再自动 `subprocess.Popen(["flutter", "run", ...])`
2. ✅ 先检查 → 不存在则礼貌提示用户手动启动 → 等待确认
3. ✅ 窗口句柄获取从进程直接找，不依赖窗口标题匹配

#### Step 0.5：窗口定位 + 尺寸调整

找到窗口后，调整到标准尺寸：

```python
import win32gui, win32con

hwnd = ...  # 从 Step 0.4 获取

win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
win32gui.SetForegroundWindow(hwnd)
time.sleep(0.15)  # 等待窗口激活
win32gui.MoveWindow(hwnd, 0, 0, 390, 844, True)
time.sleep(0.5)   # 等待窗口重绘完成

# 确认窗口实际尺寸
rect = win32gui.GetWindowRect(hwnd)
w, h = rect[2] - rect[0], rect[3] - rect[1]
print(f"Window positioned: ({rect[0]},{rect[1]}) {w}x{h}")
```

窗口尺寸固定为 **390×844（手机竖屏比例）**，位置固定在 **屏幕左上角 (0,0)**。

#### Step 0.6：基准截图

截取应用启动后的首屏画面，提交 vision 模型验证"应用正常启动、无崩溃弹窗"：

```
vision_analyze(
  image_url="screenshot.png",
  question="这张 Flutter Windows 应用截图是否正常？有无崩溃弹窗白屏？"
)
```

---

### Phase 1 — 逐页面视觉审计（5 维度）

对每个 Flutter 页面执行以下 6 步循环：

```
① 导航至目标页面（pyautogui 模拟点击/键盘）
② 等待渲染稳定（polling 截图直至连续 3 帧无变化）
③ 全屏截图（mss）
④ vision 分析截图（附带 HTML 原型对比提示）
⑤ 判断通过/警告/失败
⑥ 发现失败 → 截图存档至 Temp，记录问题描述
```

#### V1：布局完整性检查

向 vision 模型发送的提示词模板：

```
请检查这张 Flutter Windows 应用截图（页面名称：{PAGE_NAME}）。

根据以下 HTML 原型描述，检查截图中的 UI 元素是否完整呈现：

{HTML_ELEMENT_SUMMARY}

请逐项回答：
1. [元素名称] — ✅ 正常 / ❌ 缺失 / ⚠️ 位置偏移
2. [元素名称] — ...
...

然后给出总体判断：PASS / WARNING / FAIL
- PASS: 所有元素正常
- WARNING: 1-2 个非关键元素偏移
- FAIL: 关键元素缺失、布局崩溃、白屏
```

#### V2：数据显示正确性检查

在 vision 分析中增加对动态数值的识别：

```
请从截图中提取以下数值：
- 待办作业计数: ___ 项
- 连续签到天数: ___ 天
- 今日已完成题目数: ___ 题
- 用户等级: Lv.__
- 积分总数: ___

如果某个数值看起来像是写死的（如"3 项未完成"永远显示 3），请标注为 SUSPICIOUS。
```

#### V3：导航可达性检查

在 Phase 1 审计每页时，对页面上明显的"导航出口"（底部 tab、列表项、按钮）进行点击验证：

| 页面 | 导航出口 | 预期目标 | 实际结果 |
|------|---------|---------|---------|
| index.html | 待办作业链接 | homework_list_page | 点击后跳转？ |
| index.html | 底部 Tab「组卷」 | exam_home_page | 点击后跳转？ |
| index.html | 底部 Tab「我的」 | profile_page | 点击后跳转？ |

#### V4：空状态/错误态检查

如果页面上数据区域为空，检查是否有合理占位符：

```
截图中没有数据时：
- 是否有"暂无数据"或类似提示？ ✅ / ❌
- 是否有重试/刷新按钮？ ✅ / ❌
- 页面是否完全白屏？ ✅ / ❌
```

#### V5：复杂交互检查（NEW — 扩展覆盖）

详见 §四 Phase 2B。Phase 1 只做页面静态检查，不触发任何交互。

---

### Phase 2A — 用户流程审计

执行真实用户操作序列，验证多页面组合流程。每个步骤截图 + vision 校验。

#### 流程 1：登录 → 首页 → 退出

```python
# 1. 启动 app，截图登录页
# 2. 输入账号密码（预先准备的测试账号）
# 3. 点击登录
# 4. 等待首页加载，截图
# 5. 检查首页元素完整性
```

#### 流程 2：浏览试题 → 组卷

```python
# 1. 从首页 Tab 切换到「组卷」
# 2. 进入筛选页 → 设定条件 → 点击确认
# 3. 浏览试卷列表 → 点击某张试卷
# 4. 进入试卷详情 → 检查「开始做题」按钮
```

#### 流程 3：讲义浏览

```python
# 1. 从首页点击「讲义入口」
# 2. 进入课程列表 → 点击某门课程
# 3. 进入章节列表 → 点击某个章节
# 4. 查看讲义内容渲染
# 5. 检查 LaTeX 公式是否正常显示
```

#### 流程 4：个人信息管理

```python
# 1. 切换到「我的」Tab
# 2. 查看个人信息页（等级/积分/成就）
# 3. 点击「编辑资料」→ 修改昵称 → 保存
# 4. 查看成就页面
# 5. 查看积分历史
# 6. 查看做题历史
```

---

### Phase 2B — 复杂交互审计（NEW）

**范围：** 解题流程（选择/填空/步骤/地图/评分）中的游戏化交互机制。这些交互在 HTML 原型中有详细的视觉和交互说明，但 Flutter 实现容易出错。

#### 检查清单（5 项核心交互）

**I1：冷却计时器（选填题）**
| 检查点 | 方法 | 预期 |
|--------|------|------|
| 进入页面后按钮是否禁用 | 截图检查「提交答案」按钮状态 | disabled（灰色） + 倒计时文字 |
| 倒计时文字是否正确 | 截图读取文字 | "⏳ 还剩 N 秒可提交" （N=10→0） |
| 倒计时结束后按钮是否恢复 | 等 10s 后截图 | 按钮恢复可点击状态 |
| 多次进入是否重置计时 | 返回再进入，截图 | 每次新题目都从 10s 开始 |

**I2：冷却计时器（步骤题）**
| 检查点 | 方法 | 预期 |
|--------|------|------|
| 展开箭头初始状态 | 截图 | ▶ 按钮灰色禁用 + "⏳ 还剩 5 秒可查看" |
| 5s 后箭头是否恢复 | 等 5s，点击 | 点击后内容区展开 |
| 内容展开后反馈按钮出现 | 截图 | 全对 / 过程对计算错 / 不会 三个按钮可见 |

**I3：选项选择与提交（选择题）**
| 检查点 | 方法 | 预期 |
|--------|------|------|
| 点击选项是否高亮 | 点击 A，截图 | A 选项高亮（蓝色边框或背景），其他选项恢复 |
| 提交后是否正确显示结果 | 倒计时结束→提交，截图 | ✅/❌ 显示 + 解析内容展开 |
| "已完成"横幅 | 截图 | "🎉 已完成" 横幅可见 |
| 下一题 / 评分按钮 | 截图 | [下一题 →] [⭐ 评分] 两个按钮存在 |

**I4：解题地图交互**
| 检查点 | 方法 | 预期 |
|--------|------|------|
| 首次进入模式 | 截图 | "准备开始答题" 欢迎页面 + "开始答题 ▶" 按钮 |
| 多步骤树形结构 | 走完 1 步后截图 | 地图上显示第一步完成的节点 |
| 多作答切换 | 切换作答次数 | 下拉菜单出现，内容随切换更新 |
| 回顾模式 | 进入回顾模式截图 | "📋 回顾模式 · 只读浏览，不可修改" 横幅 |

**I5：评分与反馈**
| 检查点 | 方法 | 预期 |
|--------|------|------|
| 评分页面入口 | 从解题页点击「⭐ 评分」 | 跳转到评分页 |
| 评分提交 | 选择一个评分项 | 提交成功反馈 |
| 复访修改 | 回到已评分的题目 | 评分可修改 |

#### 交互检查的执行策略

- I1-I5 从属于 Group G3（解题流程），只在审计解题相关页面时执行
- 每个 I 检查项有独立的 PASS/FAIL 标记
- 交互检查的截图命名统一用 `{page}_I{序号}_{检查点}.png`

---

### Phase 3 — 边界/压力审计

#### 3.1：快速连续点击

```python
for _ in range(10):
    pyautogui.click(x, y)  # 连续点击同一按钮
    time.sleep(0.15)
# 检查有无崩溃或重复提交
```

#### 3.2：窗口缩放

```python
# 缩到极小
win32gui.MoveWindow(hwnd, 100, 100, 800, 600, True)
time.sleep(1)
screenshot + vision check

# 拖到副屏再拖回（如果有副屏）
# 最大化
win32gui.ShowWindow(hwnd, SW_MAXIMIZE)
time.sleep(0.5)
screenshot + vision check

# 恢复标准
win32gui.ShowWindow(hwnd, SW_RESTORE)
win32gui.MoveWindow(hwnd, 0, 0, 390, 844, True)
time.sleep(0.5)
```

#### 3.3：焦点切换

```python
pyautogui.hotkey('alt', 'tab')  # 切走
time.sleep(2)
pyautogui.hotkey('alt', 'tab')  # 切回
time.sleep(1)
screenshot + vision check：画面是否正常
```

#### 3.4：文件选择器取消

```python
# 在需要选择文件的页面触发选择器 → 直接点取消
pyautogui.press('escape')
# 检查返回后画面是否正常
```

---

### Phase 4 — 汇总报告

#### 报告结构

```markdown
## 视觉审计报告

### 执行概要
- 审计类型: Type V（全量/增量/快速冒烟）
- 分组: G1,G2,...（或 all）
- 审计时间: {timestamp}
- Fail-Fast: 触发于 N 个 FAIL / 未触发
- 测试用户: {username}

### 总览

| 审计阶段 | 检查项 | 通过 | 警告 | 失败 | 跳过 | 通过率 |
|---------|:-----:|:---:|:---:|:---:|:---:|:-----:|
| Phase 1 页面审计 | N | N | N | N | N | X% |
| Phase 2A 流程审计 | N | N | N | N | N | X% |
| Phase 2B 交互审计 | N | N | N | N | N | X% |
| Phase 3 边界审计 | N | N | N | N | N | X% |
| **合计** | **N** | **N** | **N** | **N** | **N** | **X%** |

### 逐页面明细

| 页面 | V1 布局 | V2 数据 | V3 导航 | V4 空态 | V5 交互 | 总体 |
|------|:-------:|:-------:|:-------:|:-------:|:-------:|:----:|
| 首页 | ✅ | ❌ | ✅ | ✅ | N/A | ⚠️ |
| 登录页 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ |
| 组卷页 | ⚠️ | ✅ | ✅ | ❌ | N/A | ⚠️ |
| solve-choice | ✅ | ⚠️ | N/A | ✅ | ❌ (I1 冷却) | ⚠️ |
| ... | | | | | | |

### 严重问题摘要

| 编号 | 严重度 | 分组 | 页面 | 问题 | 截图 | 维度 | 发现阶段 |
|:----:|:-----:|:----:|------|------|:----:|:----:|:--------:|
| V-001 | 🔴 | G1 | 首页 | pendingHomeworkCount 显示为硬编码 '3' | `V/index_V2_count.png` | V2 | Phase 1 |
| V-002 | 🔴 | G3 | solve-choice | 冷却按钮在 10s 倒计时结束后未恢复可用 | `V/solve-choice_I1_after10s.png` | I1 | Phase 2B |
| V-003 | 🟡 | G4 | lecture_content | LaTeX 渲染为空（$$...$$ 未解析） | `V/lecture_content_V1_latex.png` | V1 | Phase 2A |
| V-004 | 🔴 | G3 | 登录页 | 快速点击登录 10 次 → app 无响应 | `V/login_stress_10clicks.png` | 边界 | Phase 3 |

### 建议处理

| 优先级 | 问题计数 | 建议 |
|:------:|:-------:|------|
| P0 🔴 | N | 纳入 fix-batch-workflow 立即修复 |
| P1 🟡 | N | 在下一迭代修复 |
| P2 ⚪ | N | 关注，低优先级 |

### 半程报告（Fail-Fast 触发时）

审计在执行到 {阶段} 时触发了 Fail-Fast（{N} 个 FAIL），已暂停。

后续建议：
1. 先修复上述 P0 问题
2. 修复后以 `--group=remaining` 继续剩余页面
3. 或覆盖 `--fail-fast=0` 关闭 Fail-Fast 继续执行
```

---

## 五、截图存档规范

### 5.1 目录

```yaml
截图目录（相对于项目根）: audit_screenshots\
  例: D:\Hermes\zhangyuzhixue_app_v2\audit_screenshots\2026-07-12_1430\

每次审计创建日期子目录:
  audit_screenshots\2026-07-12_1430\   # 格式: YYYY-MM-DD_HHmm
```

原因：放在项目内可以：
- 在报告中引用相对路径（如 `audit_screenshots/2026-07-12_1430/index_V2_count.png`）
- 便于你随时查看截图
- gitignore 排除，不污染仓库

### 5.2 命名规则

```
{page}_{dimension}_{description}.png

# page     — 页面英文名（index / solve-choice / exam-pick）
# dimension— 审计维度（V1/V2/V3/V4/I1/I2/I3/I4/I5/stress）
# description — 检查点简述（cooldown_after5s / click_login_10x）
```

举例：
```
index_V2_pendingCount.png            # 首页 — 数据显示 — 待办计数
solve-choice_I1_after10s.png         # 选择题 — 冷却 — 10s后按钮状态
solve-step_I2_revealed_content.png   # 步骤题 — 展开 — 内容展开后
login_stress_click10x.png            # 登录页 — 压力 — 连续点击10次
exam-pick_V1_empty_state.png         # 组卷页 — 布局 — 空状态
```

### 5.3 清理规则

| 时机 | 操作 |
|------|------|
| 每次审计开始前 | 删除 7 天前的旧截图目录（Python: `shutil.rmtree` 遍历 `audit_screenshots/` 下的日期子目录） |
| 审计正常结束时 | 保留本次截图（供报告引用），不自动删除 |
| 用户手动清理 | `rmdir /s /q audit_screenshots` 或直接进文件管理器删除 |
| 截图自动回收 | 超过 30 天的子目录在下次审计启动时自动删除 |

### 5.4 空间预估

```
单次全量审计:
  Phase 1 (36 页面 × 每个 4 维度) ≈ 144 张截图
  Phase 2A (4 流程 × 每个 ~8 步) ≈ 32 张截图
  Phase 2B (5 交互 × 每个 ~4 检查) ≈ 20 张截图
  Phase 3 (4 测试 × 每个 ~3 截图) ≈ 12 张截图
  合计 ≈ 208 张截图
  每张 ~200KB (PNG 压缩后) → 总计 ~42MB
  保留 30 天 → ~1.3GB 峰值（假设每天跑一次）
```

---

## 六、与现有技能的衔接

### 6.1 与 `project-owner-acceptance`（Type A-G 代码审计）

- **Type V 发现问题后 → 回 Type A-G 验证根因**（如 vision 发现"待办计数硬编码"，回 Type B H6 确认代码中 Prefs key 是否缺失）
- **Type A-G 发现设计文档问题后 → 可在 Type V 中验证修复效果**
- Type V **不取代** Type A-G，而是互补

### 6.2 与 `fix-batch-workflow`

- Type V 输出的问题列表可直接作为 fix-batch-workflow 的 Phase 1 输入
- 修复后 Type V 可重新运行以验证修复效果（回归检验）

### 6.3 与 `runtime-verification`（Type R）

- Type R 读 NDJSON 日志做自动断言（非空/计数/时序）
- Type V 截图做视觉断言（布局/显示/对齐）
- 两者可以并行运行：Type R 在后台自动跑，Type V 前台驱动
- **合并方案：** 代理先跑 Type V 走查页面（确保页面能打开），再跑 Type R 读日志做自动断言

---

## 七、执行模式速查

| 模式 | 命令 | 涵盖 | 预估耗时 |
|:----:|------|------|:--------:|
| 全量 | `--group=all` | 6 Group + 4 流程 + 5 交互 + 4 边界 | 20-40 min |
| 快速冒烟 | `--group=smoke` (G1) | 核心导航 3 页 | 2-3 min |
| 解题回归 | `--group=G3` | 解题 5 页 + I1-I5 | 8-12 min |
| 组卷回归 | `--group=G2` | 组卷 9 页 | 4-6 min |
| 增量 | `--group=G3 --fail-fast=3` | 解题回归，发现问题即停 | 3-10 min |
| 自定义 | `--group=G1,G2,G6` | 自选组合 | 依组合而定 |
| 修复验证 | `--group=remaining` | 上次未完成的页面 | 依剩余量而定 |

---

## 八、注意事项 & 常见失败模式

| 场景 | 原因 | 处理 |
|------|------|------|
| screenshot 为空/黑色 | 窗口最小化或被遮挡 | 检查 `win32gui.SetForegroundWindow` 是否成功，重试 |
| pyautogui.click 无效果 | 应用窗口未获取焦点或坐标偏移 | 重新定位窗口并获取屏幕坐标 |
| vision 分析误报（正常画面判 FAIL） | DPI 缩放导致元素排列与预期不同 | 在提示词中降低样式要求，关注功能完整性 |
| vision 分析漏报（异常画面判 PASS） | 问题太细微（如单像素色差） | 转用 OpenCV 图像差值对比作为辅助 |
| 应用启动崩溃 | 缺少 VC++ 运行时 / DLL | 记录为 P0 🔴 阻塞问题 |
| 测试账号登录失败 | 密码过期 / 接口变更 | 跳过需登录的页面，报告为外部依赖问题 |
| 冷却计时器类检查超时（等 10s） | 设计如此，不能跳过 | 截图后进入等待循环（非阻塞） |
| Flutter 无响应 / 白屏 | 渲染线程崩溃 | phase 截图后检测"白屏"模式，立即记录 FAIL，重启 app |
