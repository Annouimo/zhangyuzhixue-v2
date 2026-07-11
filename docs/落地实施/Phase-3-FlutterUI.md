# Phase 3 — Flutter UI 核心（8 天，每页测）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 3 的细化执行方案。
> 状态：**待开始** | 最后更新：2026-07-11

---

## 总览

| 阶段 | 页面 | 工时 | 状态 |
|:-----|:-----|:-----|:-----|
| **3a** | MainShell + 登录/注册 | 0.5 天 | ✅ |
| **3b** | 解题模式（solve-choice/fill/map/step/rate） | 3 天 | ✅ |
| | **└ 解题流程初验**：1-2 位教师试做选填题和解答题，核对旧版数据 | (含在 3b 内) | ⬜ |
| **3c** | 讲义（courses → chapters → content） | 1 天 | ⬜ |
| **3d** | 作业（list + detail） | 0.5 天 | ⬜ |
| **3e** | 组卷（auto/pick/quicklook/history/explore/favorites/answer_sheet） | 1.5 天 | ⬜ |
| **3f** | 推荐 | 0.5 天 | ⬜ |
| **3g** | 学习统计（4 图表卡片） | 0.5 天 | ⬜ |
| **3h** | 我的（profile/edit/achievement/level/points/about/history） | 0.5 天 | ⬜ |
| | **合计** | **~8 天** | |

### 前置条件

- [x] Phase 2 全部完成：数据层（DAO + Repository + SyncEngine）就绪
- [x] Flutter 脚手架已完成（Phase 0.3），所有依赖已添加
- [x] `docs/04-UI/html/` 下 30+ HTML 原型已审阅
- [x] `MdLatexBody` 组件就绪（见 `docs/05-Flutter/components/md-latex-body/README.md`）

### 关键设计文档索引

| 文档 | 用途 |
|:-----|:-----|
| [`页面设计说明.md`](../04-UI/页面设计说明.md) | 各页面交互设计、Widget 复用指引 |
| [`设计系统.md`](../04-UI/设计系统.md) | 颜色、难度分段、间距圆角 |
| [`页面导航.md`](../01-架构/页面导航.md) | 路由关系、一级/二级页面清单 |
| [`data-db标记规范.md`](../04-UI/data-db标记规范.md) | HTML→Repository 映射契约 |
| [`Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | Widget 组织、路由方案、Prefs 前缀 |
| [`数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | Repository→DAO 层间契约 |
| [`docs/04-UI/html/*.html`](../04-UI/html/) | 30+ HTML 原型（交互参考） |

---

## 基础骨架（先于 3a）

### 涉及文件

```
flutter_app/lib/
├── main.dart                    # 修改：初始化 + runApp + 主题
├── app_theme.dart               # 新建：ThemeData（设计系统颜色/圆角/间距）
├── router.dart                  # 新建：路由表（所有页面路径）
├── widgets/
│   ├── md_latex_body.dart       # 复制：从组件库复制到此处
│   └── shared/                  # 新建：通用 Widget 目录
│       ├── loading_indicator.dart
│       ├── error_placeholder.dart
│       └── empty_placeholder.dart
└── pages/                       # 新建：页面目录
```

### 实现要点

**main.dart 主题配置：**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs().init();
  ApiClient().init();
  await DatabaseProvider().init();
  ConnectivityMonitor().init();
  SyncManager().init(SyncQueueDao(DatabaseProvider().appDb), SyncApi(ApiClient()), DatabaseProvider());
  SyncManager().onAppStart();
  runApp(const ZhangyuzhixueApp());
}
```

**app_theme.dart：** 从 `设计系统.md` 提取颜色常量：

```dart
class AppColors {
  static const primary = Color(0xFF4A6CF7);
  static const primaryLight = Color(0xFFEEF1FF);
  static const background = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}
```

间距/圆角常量：

| 名称 | 值 |
|:-----|:---|
| base spacing | 16.0 |
| card radius | 12.0 |
| button radius | 8.0 |
| max content width | 480.0 |

**router.dart：** 基于 `go_router`（需加 pubspec 依赖）或原生 Navigator 2.0，路由表包含 Phase 3 全部页面。

**Widget 复用原则（来自页面设计说明 §1）：**
- 选填题流程抽取 `SolveFlowWidget`（冷却→提交→结果→完成横幅）
- 解答题步骤卡抽取 `StepCardWidget`（冷却箭头→展开→反馈按钮）
- 筛选模块（组卷、推荐共用）抽取 `FilterPanel`

### 验证方式

```bash
dart run # 确认主题设置正确、启动无报错
# 路由手动验证：导航到每个路径不 crash
```

### 注意事项

- `go_router` 需加到 pubspec.yaml（非 Phase 0 定义的依赖列表，需 `flutter pub add go_router`）
- 每个 Widget 覆盖 加载中 / 空状态 / 正常数据 / 错误状态 / 边界数据

---

## 3a — MainShell + 登录/注册（0.5 天）

### 涉及文件

```
flutter_app/lib/pages/
├── main_shell.dart              # 新建：底部导航框架（4 Tab）
├── login_page.dart              # 新建：登录页
├── register_page.dart           # 新建：注册页（邀请码 + 表单）
└── index_page.dart              # 新建：首页（今日待办 + 快捷入口）
```

### 实现要点

**MainShell：** 底部 4 Tab（首页/作业/讲义/我的），`BottomNavigationBar` + `IndexedStack` 保持页面状态。

**登录页（login_page.dart）：**

| 元素 | data-db 映射 | 说明 |
|:-----|:-------------|:-----|
| 用户名输入框 | `data-db-bind="auth.login.username"` | TextEditingController |
| 密码输入框 | `data-db-bind="auth.login.password"` | 同上，obscureText |
| 登录按钮 | `data-db-action="auth.login()"` | 调用 AuthRepository.login |
| 错误提示 | — | SnackBar 展示错误码对应文案 |
| 跳转注册 | — | Navigator.push 到 RegisterPage |

**首页（index_page.dart）：**

| 区域 | data-db 映射 | 说明 |
|:-----|:-------------|:-----|
| 待办作业数 | `data-db="assign.pendingCount"` | 右上角 badge |
| 快捷入口 | — | 推荐 / 组卷 / 统计，静态图标网格 |
| 上次学习内容 | — | 从 user.db 取最近 submission 的题目，可选 |

**注册页（register_page.dart）：**

| 字段 | data-db 映射 |
|:-----|:-------------|
| 邀请码 | `data-db-bind="auth.register.invitationCode"` |
| 用户名 | `data-db-bind="auth.register.username"` |
| 密码 | `data-db-bind="auth.register.password"` |
| 姓名 | `data-db-bind="auth.register.realName"` |
| 手机号 | `data-db-bind="auth.register.phone"` |
| 高考年份 | `data-db-bind="auth.register.gaokaoYear"` |
| 提交 | `data-db-action="auth.register()"` |

**登录后导航：** 成功登录 → 检查 `preference.count` → 0 则跳 `preference_welcome`（Phase 4），否则跳 MainShell。

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| LoginPage | 登录成功→跳 MainShell | 1 |
| LoginPage | 登录失败→SnackBar 提示 | 2 |
| LoginPage | 输入验证（空值/格式） | 2 |
| RegisterPage | 邀请码校验成功/失败 | 2 |
| RegisterPage | 注册成功→跳登录页 | 1 |
| MainShell | 4 Tab 切换正常 | 1 |
| IndexPage | 加载中/有数据/空状态 | 3 |

**合计：~12 个测试用例**

### 注意事项

- 登录成功需在本地保存 token + userCache（AppPrefs）
- register 成功**不返回 token**，跳转登录页
- MainShell 中首页的「今日待办作业数」只在登录后有数据，未登录显示占位

---

## 3b — 解题模式（3 天，最复杂步骤）

### 涉及文件

```
flutter_app/lib/pages/solve/
├── solve_choice_page.dart       # 新建：选择题解题页
├── solve_fill_page.dart         # 新建：填空题解题页
├── solve_map_page.dart          # 新建：解答题地图页（步骤导航）
├── solve_step_page.dart         # 新建：解答题步骤详情页
├── solve_rate_page.dart         # 新建：评分页（3维×10星）
├── widgets/
│   ├── solve_flow_widget.dart   # 新建：选填共用流程 Widget
│   ├── step_card_widget.dart    # 新建：解答步骤卡 Widget
│   ├── feedback_buttons.dart    # 新建：反馈按钮组
│   └── cooling_timer.dart       # 新建：冷却倒计时组件
```

### 实现要点

#### 3b.1 — 选填共用流程（SolveFlowWidget）

从 `solve-choice.html` / `solve-fill.html` 原型抽取共享流程：

```
[题干区 — MdLatexBody]
[选项区 — ChoiceGrid / 填空输入框]   （仅选择题/填空题不同）
[冷却计时器 — CoolingTimer]
  └───────── 显示「提交」或「查看答案」按钮
[结果展示区 — 正确/错误 + 解析]
[完成横幅 — 🎉 已完成 + 「下一题」「⭐ 评分」]
```

**状态机（ProgressRepository.getPreviousState 驱动）：**

| 状态 | 行为 |
|:-----|:-----|
| 首次未提交 | 10s 冷却 → 按钮可用 → 用户提交 → 展示结果 → 完成横幅 |
| 复访已完成 | 跳过冷却，直接展示结果和完成横幅 |
| 复访已评分 | 额外显示已评分分数 |

**与 Repository 的绑定：**

| data-db | Repository 方法 |
|:--------|:---------------|
| `question.getDetail(id)` | QuestionRepository.getDetail(questionId) → QuestionDetail |
| `progress.getPreviousState(id)` | ProgressRepository.getPreviousState(questionId) → PreviousSolveState? |
| `progress.createAttempt()` | ProgressRepository.createAttempt(questionId) → SubmissionDetail |
| `progress.submitAnswer()` | ProgressRepository.submitAnswer(questionId, answer, attempt) → bool isCorrect |
| `progress.getSolveState()` | ProgressRepository.getSolveState(questionId) → SolveState |

**冷却规则（来自页面设计说明 §1）：**
- 选填 10s，每步解答 5s（默认值，可通过 SystemConfig 配置）
- 按钮 `opacity: 0.4; cursor: not-allowed` 形态
- 按钮下方 `⏳ 还剩 N 秒可提交`
- 复访不启动冷却

#### 3b.2 — 解答步骤卡（StepCardWidget）

```
[步骤标题 + 知识标签（可点击 → 弹出知识卡片弹层）]
[冷却箭头按钮 + ⏳ 倒计时]
  ↓ 用户点击箭头
[解析内容展开 — MdLatexBody]
[反馈按钮组 — FullCorrect / PartialCorrect / Wrong]
```

**交互序列：**
1. 当前步卡片显示 → 5s 冷却（箭头禁用）
2. 箭头恢复可用 → 用户点击 ▶
3. 解析内容展开 → 反馈按钮出现
4. 用户选择反馈 → 推到下一步（或最后一步显示完成横幅）

**知识卡片弹层：** 复用组件，点击知识标签弹出，展示卡片名称 + 内容（MdLatexBody 渲染 LaTeX）。

#### 3b.3 — 地图页（SolveMapPage）

解答题入口页，展示题目的 N 步骤概览（类似进度图）：

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 步骤列表 | `data-db-loop="progress.getSolveState.subQuestions"` | 各小题的步骤汇总 |
| 已完成的步 | — | 绿色标记 + 已展开状态 |
| 当前步 | — | 可点击进入 solve_step_page |
| 未做的步 | — | 灰色锁定 |

#### 3b.4 — 评分页（SolveRatePage）

三题型共享入口：

| 维度 | 说明 | 数据源 |
|:-----|:-----|:-------|
| 难度 | 10星，显示算法难度分对比 | QuestionRating |
| 计算量 | 10星，显示算法计算量分对比 | QuestionRating |
| 优雅度 | 10星，无算法分对比 | QuestionRating |

允许复访修改（`data-db-action="rating.submit()"` → SyncApi 入队）。

### ✅ 解题流程初验（含在 3b 内）

**时机：** 3b 全部实现后。

**流程：**
1. 2 位教师用测试账号登录
2. 各做 3 道选择题、3 道填空题、2 道解答题
3. 核对 items：
   - 冷却时长（选填 10s / 解答每步 5s）
   - 反馈文案（全对/部分对/不对）
   - 数据正确性（对错判定与旧版一致）
   - 评分页可见
4. 收集反馈 → 修复 → 复测

**产出：** 教师签字确认解题流程可用。

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| SolveFlowWidget | 首次：冷却→提交→正确/错误→完成横幅 | 4 |
| SolveFlowWidget | 复访已完成：跳过冷却直接展示 | 2 |
| SolveFlowWidget | 复访已评分：额外显示评分 | 1 |
| StepCardWidget | 冷却→箭头展开→反馈→下一步 | 3 |
| StepCardWidget | 最后一步→完成横幅 | 1 |
| StepCardWidget | 知识标签可点→弹层显示 | 1 |
| FeedbackButtons | 三种反馈可点击状态 | 3 |
| CoolingTimer | 10s/5s 倒计时正确 | 2 |
| SolveMapPage | 步骤概览渲染 | 1 |
| SolveRatePage | 3组×10星评分/修改 | 2 |

**合计：~20 个测试用例**

### 注意事项

- 解题页是核心交互——**首次与复访的 UI 差异**请严格对照页面设计说明中的「首次 vs 复访 UI 差异」表
- 反馈数据写入后通过 SyncApi 入队（不直接请求服务端）
- 冷却时长从 SystemConfig 读取（默认选填 10s / 解答每步 5s）
- 知识卡片弹层点击外部关闭

---

## 3c — 讲义（courses → chapters → content，1 天）

### 涉及文件

```
flutter_app/lib/pages/lecture/
├── lecture_courses_page.dart     # 新建：课程列表
├── lecture_chapters_page.dart    # 新建：章节目录
├── lecture_content_page.dart     # 新建：讲义正文
└── widgets/lecture_pager.dart    # 新建：翻页/展开栏
```

### 实现要点

**三级下钻：** `lecture_courses_page` → `lecture_chapters_page` → `lecture_content_page`

**LectureContentPage 核心逻辑（来自页面设计说明 §2）：**

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 正文区 | `data-db-loop="lecture.getContentParsed.pages[].blocks[]"` | `parseMdContent()` 解析结果 |
| 翻页栏 | — | 底部固定栏（◀/▶ + 页码） |
| 知识标签 | — | 可点击 → 弹知识卡片弹层（复用） |

**parseMdContent 解析规则：**
- 分隔符 `<!-- pagebreak -->` → 分页
- 分隔符 `<!-- reveal -->` → 同页内展开块
- 每页分为 `blocks[0..N]`，blocks[0] 默认可见，blocks[1..N] 初始隐藏
- blocks 用 `MdLatexBody` 渲染 Markdown + LaTeX

**翻页栏交互：**
- ◀：有已展开块则收回，无则翻上一页
- ▶：有未展开块则展开，无则翻下一页
- 页码格式：「第 X / Y 页 · 展开 A / B」
- 全部展开/收回后按钮切换为翻页模式（蓝底白字样式变化）

**路由：** `/lecture/content?id=1&page=3`

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| parseMdContent | pagebreak/reveal 解析正确 | 3 |
| parseMdContent | 空内容/纯文本/LaTeX | 3 |
| LectureContentPage | 翻页/展开/收回交互 | 4 |
| LectureContentPage | 页码计算正确 | 2 |
| LectureContentPage | 知识标签可点击 | 1 |
| LectureList | 课程列表渲染 | 1 |
| ChapterList | 章节列表渲染 | 1 |

**合计：~15 个测试用例**

### 注意事项

- `parseMdContent()` 是纯内存函数（输入 string → 输出结构化对象），不持久化到 DB
- 讲义内容不从服务端实时拉取，从 lectures.db 的 `lecture_content` 表读取（镜像机制）
- 翻页栏的「全部展开后按钮变翻页模式」需正确实现高亮

---

## 3d — 作业（list + detail，0.5 天）

### 涉及文件

```
flutter_app/lib/pages/assignment/
├── homework_list_page.dart       # 新建：作业列表
├── homework_detail_page.dart     # 新建：作业详情
└── widgets/assignment_card.dart  # 新建：作业卡片（复用）
```

### 实现要点

**作业列表页（homework_list_page.dart）：**

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 待办作业列表 | `data-db-loop="assign.getPending"` | AssignmentCard 列表 |
| 各卡片标题 | `data-db="assign.getPending[].title"` | — |
| 各卡片课程名 | `data-db="assign.getPending[].courseName"` | — |
| 各卡片完成数 | `data-db="assign.getPending[].doneCount"` | 格式 "完成 3/10" |
| 各卡片截止日 | `data-db="assign.getPending[].deadline"` | 颜色高亮（即将截止/已过期） |
| 空状态 | `data-db-empty="暂无待办作业"` | 空列表占位 |

**作业详情页（homework_detail_page.dart）：**

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 作业标题 | `data-db="assign.getDetail.title"` | — |
| 题目列表 | `data-db-loop="assign.getDetail.questions"` | 可点击进入解题页 |
| 完成状态 | — | 各题目旁的 ✅/⬜ 标记 |
| PDF 下载 | `data-db-action="assign.downloadPdf()"` | → PdfHelper |

**路由：** `/homework/detail?id=1`

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| 作业列表 | 有数据/空/加载中 | 3 |
| 作业卡片 | 倒计时/超期样式 | 2 |
| 作业详情 | 标题+题目列表渲染 | 2 |
| 作业详情 | 完成进度统计正确 | 1 |

**合计：~8 个测试用例**

### 注意事项

- 作业数据来自 assets.db 的 `assignment` 表（镜像），纯本地读取，不依赖网络
- 作业的「完成状态」从 user.db 的 `submission_detail` 推算（跨库查询）

---

## 3e — 组卷（auto/pick/quicklook/history/explore/favorites/answer_sheet，1.5 天）

### 涉及文件

```
flutter_app/lib/pages/exam/
├── exam_auto_page.dart                 # 新建：智能组卷
├── exam_pick_page.dart                 # 新建：自主选题
├── exam_quicklook_page.dart            # 新建：预览（自己）
├── exam_quicklook_other_page.dart      # 新建：预览（他人）
├── exam_history_page.dart              # 新建：我的组卷
├── exam_explore_page.dart              # 新建：发现组卷
├── exam_favorites_page.dart            # 新建：我的收藏
├── answer_sheet_page.dart              # 新建：快对答案
├── widgets/
│   ├── filter_panel.dart               # 新建：筛选模块（复用 3e/3f）
│   ├── difficulty_slider.dart          # 新建：难度5段滑块
│   └── paper_card.dart                 # 新建：组卷卡片（列表复用）
```

### 实现要点

#### 筛选模块（FilterPanel + DifficultySlider）

筛选模块在 `exam_auto`、`exam_pick`、`recommend` 三页共用：

| 筛选条件 | 组件 | 数据源 |
|:---------|:-----|:-------|
| 年份 | 多选胶囊 | `QuestionDao.getFilterOptions()` |
| 区 | 多选胶囊 | 同上 |
| 概念标签 | 多选层级 | 同上 |
| 题型 | 三选（选/填/解） | 静态 |
| 难度 | 5段滑块 | `DifficultySlider` |
| 计算量 | 5段滑块 | 同上 |

**DifficultySlider：** 双端滑块，显示 5 段标签（基础/中档/中难/较难/压轴），边界位置参看设计系统.md。

#### 智能组卷（ExamAutoPage）

| 步骤 | 内容 | 数据映射 |
|:-----|:-----|:---------|
| 筛选 | FilterPanel → 实时更新计数 | `data-db="exam.getPoolStats"` |
| 题型配比 | 选10填5解6（默认，可调节） | ExamRepository.getPoolStats |
| 难度调优 | 滑竿调整目标难度区间 | — |
| 确认组卷 | `data-db-action="exam.confirm()"` | → _ExamGenerator |

**难度调优规则：**
- 上下限 = 当前筛选池实际极值，动态变化
- 题型默认值从 DB 读取

#### 自主选题（ExamPickPage）

| 元素 | 说明 |
|:-----|:-----|
| 筛选面板 | FilterPanel（同上） |
| 题目列表 | 逐题显示 stem（MdLatexBody 前几行截断） |
| 勾选框 | 独立维护 `Set<int> selectedIds`，跨筛选保留 |
| 底部固定条 | 已选 N 题 + 「确认组卷」按钮 |

#### 预览页（QuicklookPage）

| 版本 | 功能 |
|:-----|:-----|
| 自己 | 公开开关、删除按钮、PDF 下载 |
| 他人 | 点赞按钮、收藏按钮、PDF 下载 |

#### 列表页（History / Explore / Favorites）

| 页面 | 数据源 | 排序方式 |
|:-----|:-------|:---------|
| 我的组卷 | `ExamDao.getMyPapers()` | 按最近修改 |
| 发现组卷 | `ExamApi.getExploreList()` | 4种排序（热度/最新/点赞/收藏） |
| 我的收藏 | `ExamDao.getFavorites()` | 按收藏时间 |

#### 快对答案（AnswerSheetPage）

| 元素 | data-db |
|:-----|:--------|
| 题目精简列表 | `data-db-loop="exam.getQuickAnswers"` |
| 每题答案 | `data-db="exam.getQuickAnswers[].answer"` |

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| FilterPanel | 条件组合筛选计数 | 3 |
| DifficultySlider | 双端滑块边界 | 2 |
| ExamAutoPage | 智能组卷全流程（筛选→确认→创建） | 2 |
| ExamPickPage | 勾选→跨筛选保留 | 2 |
| ExamPickPage | 底部固定条计数 | 1 |
| QuicklookPage | 公开/删除/下载 | 2 |
| HistoryPage | 列表渲染 + 开关 | 2 |
| ExplorePage | 排序切换 | 1 |
| FavoritesPage | 收藏列表 | 1 |
| AnswerSheetPage | 答案列表渲染 | 1 |

**合计：~17 个测试用例**

### 注意事项

- 自主选题的 `selectedIds` 跨筛选保留：选中的题目即使因筛选隐藏仍保留在 `Set<int>` 中
- 智能组卷的 `_ExamGenerator.confirm()` 在 Phase 2.4 已实现（贪心选 + 交换 3 轮）
- 点赞/收藏需要 SyncApi 入队（多人操作场景）

---

## 3f — 推荐（0.5 天）

### 涉及文件

```
flutter_app/lib/pages/
├── recommend_page.dart          # 新建：推荐页（双模式）
└── widgets/recommend_card.dart  # 新建：题目推荐卡片
```

### 实现要点

**双模式切换：**

| 模式 | 触发条件 | 数据源 |
|:-----|:---------|:-------|
| 🔮 智能推荐 | 做题记录 ≥ 5 条 | `_RecommendationEngine` |
| 📋 偏好推荐 | 有偏好预设 | PreferenceRepository |

**默认策略（来自页面设计说明 §4）：**
- 做题 < 5 条且有偏好 → 偏好推荐
- 做题 ≥ 5 条 → 智能推荐
- 两者都有 → 右上角提供切换 Tab

**推荐卡片：** 显示题目标题（截断）、题型标签、难度段标签。

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 推荐列表 | `data-db-loop="recommend.getSmartList"` 或 `"recommend.getPreferenceList"` | — |
| 卡片标题 | `data-db="recommend.getSmartList[].title"` | stem 截断前 50 字 |
| 题型标签 | — | 选择/填空/解答 |
| 难度标签 | — | 基础/中档/中难/较难/压轴 |
| 空状态 | `data-db-empty="暂无推荐，先去组卷或做几道题吧"` | — |

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| 双模式 | 智能/偏好默认策略正确 | 2 |
| 双模式 | 手动切换 | 1 |
| 推荐列表 | 有数据/空列表 | 2 |
| 推荐卡片 | 渲染正确 | 1 |

**合计：~6 个测试用例**

### 注意事项

- `_RecommendationEngine` 冷启动（<5 条记录）返回空列表，由 UI 显示引导文案
- 推荐页面进入解题时 +1 冷却校验，复用 SolveFlowWidget

---

## 3g — 学习统计（0.5 天）

### 涉及文件

```
flutter_app/lib/pages/
├── statistics_page.dart         # 新建：统计页
└── widgets/
    ├── heatmap_chart.dart       # 新建：做题热力图（4种自适应）
    ├── trend_chart.dart         # 新建：折线图（正确率/积分）
    ├── donut_chart.dart         # 新建：环形图（题型分布）
    └── time_range_picker.dart   # 新建：时间范围 pill 选择
```

### 实现要点

**总体布局：** 顶部概览卡片 + 时间范围 pill（5 选 1） + 4 个图表卡片。

**时间范围切换（来自页面设计说明 §5）：**

| 选项 | 值 | 显示模式 |
|:-----|:---|:---------|
| 近一周 | 7天 | 水平条形图（天/格） |
| 近一月 | 30天 | 7行周历（天/格） |
| 近三月 | 90天 | 7行周历（天/格） |
| 近一年 | 365天 | 周/格贡献图 |
| 全部 | 动态 | 月/格 |

**自适应粒度规则：**

| 天数范围 | 模式 |
|:---------|:-----|
| ≤ 14 | 水平条形图 |
| 15–90 | 7行周历 |
| 91–730 | 周/格贡献图 |
| > 730 | 月/格 |

**4 个图表卡片：**

| 卡片 | 实现方式 | data-db |
|:-----|:---------|:--------|
| 做题热力图 | div + CSS 染色 (lv0~lv3) | `stats.getDailyRecords` |
| 正确率趋势 | SVG polyline + 网格线 | `stats.getAccuracyTrend` |
| 积分累计趋势 | SVG polyline + 动态度量 | `stats.getPointsTrend` |
| 题型分布 | conic-gradient + 图例 | `stats.getDistribution` |

**Flutter 图表实现方案（三选一，推荐第二种）：**

| 方案 | 评价 |
|:-----|:-----|
| `fl_chart` 库 | 功能全但包体大，非必需不采用 |
| **纯 CustomPaint + Canvas** | **推荐**——4 个图表都不复杂，用 Canvas 直绘无依赖 |
| `syncfusion_flutter_charts` | 包体更大，功能冗余 |

**技术选型决策：** 用 `CustomPaint` + `Canvas` 实现全部 4 个图表。热力图用 `GridView` + CSS 染色（`Container` 背景色）；折线图用 `CustomPainter` 绘制 polyline + circle；环形图用 `CustomPainter` 的 drawArc。

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| 时间范围切换 | 5种选择→数据正确刷新 | 3 |
| 自适应粒度 | 7天→条形图、30天→周历 | 2 |
| 热力图 | 染色级别正确 | 1 |
| 折线图（正确率） | SVG 描点正确 | 1 |
| 折线图（积分） | 无数据→显示占位 | 1 |
| 环形图 | 题型分布比例正确 | 1 |

**合计：~9 个测试用例**

### 注意事项

- 图表数据全部来自本地 user.db（StatisticsRepository），离线可用
- 热力图染色 0~3 级按当期内最大值归一化，缺失日期自动 lv0
- 无数据时不显示空白，而是显示「暂无学习数据」占位图

---

## 3h — 我的（profile/edit/achievement/level/points/about/history，0.5 天）

### 涉及文件

```
flutter_app/lib/pages/profile/
├── profile_page.dart            # 新建：个人主页
├── profile_edit_page.dart       # 新建：编辑资料
├── achievement_page.dart        # 新建：成就列表
├── level_detail_page.dart       # 新建：等级进度
├── points_page.dart             # 新建：积分流水
├── about_page.dart              # 新建：关于
└── question_history_page.dart   # 新建：做题历史
```

### 实现要点

**个人主页（profile_page.dart）：**

| 区域 | data-db | 说明 |
|:-----|:--------|:-----|
| 头像 | `data-db="user.getInfo.avatar"` | CircleAvatar + 占位 |
| 用户名 | `data-db="user.getInfo.realName"` | — |
| 等级 | `data-db="user.getInfo.level"` | 等级标签 |
| 积分 | `data-db="user.getInfo.pointsSummary"` | 显示汇总 |
| 功能入口列表 | — | 静态 6 项（编辑/成就/等级/积分/历史/关于） |

**编辑资料（profile_edit_page.dart）：**

| 字段 | data-db-bind | 说明 |
|:-----|:-------------|:-----|
| 姓名 | `auth.update.realName` | — |
| 手机 | `auth.update.phone` | — |
| 学校 | `auth.update.school` | — |
| 高考年份 | `auth.update.gaokaoYear` | — |
| 保存 | `data-db-action="user.update()"` | → UserApi.updateProfile |

**成就页（achievement_page.dart）：**

| 元素 | data-db |
|:-----|:--------|
| 成就分类列表 | `data-db-loop="achievement.getCategories"` |
| 各成就 | `data-db="achievement.getCategories[].achievements[]"` |
| 已解锁标记 | — | ✅ 徽章 |
| 进度条 | — | `is_unlocked` / `progress` |

**等级页（level_detail_page.dart）：** 等级进度条 + 各等级分段说明（从 LevelConfig 表读取）。

**积分流水页（points_page.dart）：** 按时间倒序显示 PointsTransaction 列表。

**关于页（about_page.dart）：** 版本号 + 版权信息 + 隐私政策/用户协议链接。

**做题历史（question_history_page.dart）：** 按时间倒序显示 submission 记录，可点击进入解题页复访。

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| ProfilePage | 用户信息展示 | 1 |
| ProfilePage | 功能入口跳转 | 1 |
| ProfileEditPage | 加载现有数据→保存 | 2 |
| AchievementPage | 分类列表+进度条 | 2 |
| LevelDetailPage | 等级进度 | 1 |
| PointsPage | 流水列表 | 1 |
| AboutPage | 版本显示 | 1 |
| HistoryPage | 历史记录列表 | 1 |

**合计：~10 个测试用例**

### 注意事项

- 编辑资料的 avatar 上传用 user_api.uploadAvatar（FormData multipart）
- 成就/等级/积分数据全来自本地 user.db（`AchievementDao` / `UserDao`）
- 做题历史可通过 `ProgressDao` 查询所有 submission_detail（按 created_at 降序）

---

## 测试汇总

| 子步骤 | 测试数 |
|:-------|:------:|
| 3a MainShell + 登录/注册 | ~12 |
| 3b 解题模式 | ~20 |
| 3c 讲义 | ~15 |
| 3d 作业 | ~8 |
| 3e 组卷 | ~17 |
| 3f 推荐 | ~6 |
| 3g 学习统计 | ~9 |
| 3h 我的 | ~10 |
| **合计** | **~97** |

> 测试嵌入到每个子步骤中，做到哪步测到哪步，不攒到最后。
> 每个 Widget 覆盖 加载中 / 空状态 / 正常数据 / 错误状态 / 边界数据。

---

## 路由表一览

| 路径 | 页面 | 对应子步骤 |
|:-----|:-----|:----------|
| `/` | MainShell | 3a |
| `/login` | LoginPage | 3a |
| `/register` | RegisterPage | 3a |
| `/solve/choice?id=` | SolveChoicePage | 3b |
| `/solve/fill?id=` | SolveFillPage | 3b |
| `/solve/map?id=` | SolveMapPage | 3b |
| `/solve/step?id=&sub=` | SolveStepPage | 3b |
| `/solve/rate?id=` | SolveRatePage | 3b |
| `/lecture/courses` | LectureCoursesPage | 3c |
| `/lecture/chapters?id=` | LectureChaptersPage | 3c |
| `/lecture/content?id=&page=` | LectureContentPage | 3c |
| `/homework` | HomeworkListPage | 3d |
| `/homework/detail?id=` | HomeworkDetailPage | 3d |
| `/exam/auto` | ExamAutoPage | 3e |
| `/exam/pick` | ExamPickPage | 3e |
| `/exam/quicklook?id=` | ExamQuicklookPage | 3e |
| `/exam/history` | ExamHistoryPage | 3e |
| `/exam/explore` | ExamExplorePage | 3e |
| `/exam/favorites` | ExamFavoritesPage | 3e |
| `/exam/answersheet?id=` | AnswerSheetPage | 3e |
| `/recommend` | RecommendPage | 3f |
| `/statistics` | StatisticsPage | 3g |
| `/profile` | ProfilePage | 3h |
| `/profile/edit` | ProfileEditPage | 3h |
| `/profile/achievement` | AchievementPage | 3h |
| `/profile/level` | LevelDetailPage | 3h |
| `/profile/points` | PointsPage | 3h |
| `/profile/about` | AboutPage | 3h |
| `/profile/history` | QuestionHistoryPage | 3h |

---

## 验收标准

1. 全部 ~97 个页面 Widget 测试通过
2. 登录/注册流程完整（含邀请码校验、登录后自动跳转 MainShell）
3. 解题模式：选填和解答题交互序列与 HTML 原型一致（冷却→提交→反馈→评分）
4. 解题流程初验：2 位教师签字确认
5. 讲义三级下钻 + 翻页展开交互正确
6. 作业列表/详情功能就位，数据从 assets.db 读取
7. 组卷全流程（智能/自主/预览/列表/收藏）可用
8. 推荐页双模式切换正确
9. 统计页 4 图表 + 时间范围切换可用
10. 个人主页 + 6 个子页面跳转正常
11. 每个 Widget 覆盖 加载中 / 空状态 / 正常数据 / 错误状态 / 边界数据
