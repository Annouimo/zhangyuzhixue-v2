# UI 重构第三批说明

本批建立在第一、二批之上。统一做题与答案解析流程。

## 改动范围

### 做题页面（5 个页面）
- `solve_choice_page.dart` — 选择题页
- `solve_fill_page.dart` — 填空题页
- `solve_map_page.dart` — 解题地图页
- `solve_rate_page.dart` — 评分页
- `solve_step_page.dart` — 解题步骤页

全部使用统一设计令牌和共享组件。

### 共享做题组件（新增 2 个，更新 6 个）

**新增：**
- `SolveQuestionSurface` — 统一题目展示区（题干、图片、知识点标签、题号进度）
- `SolveResultCard` — 统一结果卡片（正确/错误状态、答案对比）

**更新：**
- `CoolingTimer` — 冷却计时器
- `DoneBanner` — 完成横幅
- `FeedbackButtons` — 反馈按钮
- `SolveFlowWidget` — 解题流程
- `SolveRevealWidget` — 答案揭示
- `StepCardWidget` — 步骤卡片

统一题型展示、题号进度条、选项状态（默认/按下/选中/正确/错误/未选/禁用/已提交）、操作区域（上/下一题、提交、收藏、反馈、解析）、答题卡、解析区域等。

## 文件清单

- `Phase3/ui-refactor-phase3.patch` — 第三批补丁文件
