## 导航与页面结构

### 一级页（底部导航）

| 页面 | 路径 | 说明 |
|------|------|------|
| 作业 | `homework.html` | 作业列表 + 讲义入口 |
| 推荐 | `recommend.html` | 智能推荐 / 偏好推荐双模式 |
| 组卷 | `exam.html` | 新组卷 + 三个功能入口 |
| 我的 | `profile.html` | 个人信息 + 功能入口列表 |

所有子页面均无底部导航。

### 解题模式

`solve.html` — 解题步骤状态机：箭头→展开步骤→反馈→下一步→完成→恭喜。所有揭示步骤保留可见。

知识卡片弹层 + 10星评分 + 算法分对比。

### 讲义

`lecture_courses.html` → `lecture_chapters.html` → `lecture_content.html`

讲义底部固定翻页栏，内容区内嵌 LaTeX 公式渲染。

---

## 组卷系统

### 页面

| 页面 | 路径 | 说明 |
|------|------|------|
| 智能组卷 | `paper_auto.html` | 筛选 + 题型 stepper + 难度调优 |
| 自主选题 | `paper_pick.html` | 筛选 + 逐题勾选，底部固定条 |
| 预览（自己） | `paper_quicklook.html` | 公开开关 + 删除 |
| 预览（他人） | `paper_quicklook_other.html` | 点赞 + 收藏 |
| 我的组卷 | `paper_history.html` | 列表 + 公开/私密开关 |
| 发现组卷 | `paper_explore.html` | 4种排序 + 点赞 + 收藏 |
| 我的收藏 | `paper_favorites.html` | 收藏的他人试卷 |
| 快对答案 | `answer_sheet.html` | 答案速览列表 |

### Flutter 实现注意

- 自主选题跨筛选保留：独立维护 `Set<int> selectedIds`
- 题型默认值（选10填5解6）及高考参考难度从 DB 读取
- `exam_repository.dart` 新增：`autoGenerate(counts, targetDifficulty)`、`getFilterPoolStats()`、`saveFilterPreset()`、`loadFilterPresets()`
- 难度调优上下限 = 当前筛选池实际极值，动态变化
- 点赞、收藏需服务端接口（多人操作）
- Drift 新增 `filter_presets` 表、`likes` 表
- 组卷生成后在 `paper_auto/paper_pick` → `paper_quicklook` 间跳转

---

## 学习偏好

### 页面

| 页面 | 路径 | 说明 |
|------|------|------|
| 偏好管理 | `preference_list.html` | 列表 + 编辑/删除 |
| 偏好编辑 | `preference_edit.html` | 新建/编辑 |
| 首次引导 | `preference_welcome.html` | 注册后无偏好时跳转至此 |
| 推荐页 | `recommend.html` | 🔮智能推荐 / 📋偏好推荐 |

### Flutter 实现注意

- 登录/注册成功 → 检查 `preference.count` → 0 则跳转 `preference_welcome.html`
- 推荐页默认模式：做题<5题且有偏好 → 偏好推荐；做题≥5 → 智能推荐
- 偏好数据存本地 `filter_presets` 表，同步到服务器

---

## 退出页面评价

弹出时机：返回按钮 20%概率（`solve`/`paper_quicklook`/`lecture_content`），同页 24h 冷却，停留>30s 触发。

- `rating_repository.dart` 补 `savePageRating()` 方法
- 冷却时间存本地 SharedPreferences 或 SQLite metadata
- 对话框用 `showDialog` 或自定义 Overlay
