# 页面刷新机制重构计划

## 当前完成状态 ✅

全量编译通过（3 个 info 级别 `use_build_context_synchronously` 为预先存在的警告，非本改动引入）

---

## 阶段一：`AsyncLoadWidget<T>` 泛型组件 ✅ 已完成

### 组件位置
`flutter_app/lib/widgets/shared/async_load_widget.dart`

### 组件 API

```dart
AsyncLoadWidget<T>(
  key: _loadKey,                                 // 可选，外部调用 refresh/optimisticUpdate
  onLoad: () => _repo.getMethod(),               // 异步数据源
  builder: (ctx, data) => Widget,                // 数据就绪后构建 UI
  emptyWidget: EmptyPlaceholder(...),            // 可选，空状态
  pullToRefresh: true,                           // 默认启用下拉刷新
  loadingMessage: '加载中…',                      // 可选 loading 文案
  errorMessage: '加载失败',                        // 可选错误文案
)
```

### AsyncLoadWidgetState 公开方法

| 方法 | 用途 |
|------|------|
| `refresh()` | 手动触发全量重新加载 |
| `optimisticUpdate(fn)` | 乐观更新：在 API 返回前就地修改当前数据 |

### 已迁移页面（4 页）

| 页面 | 改动 |
|------|------|
| ExamHistoryPage | 全量替换，用 GlobalKey 支持 _deleteExam 后刷新 |
| ExamFavoritesPage | 全量替换，用 optimisticUpdate 支持点赞/收藏 |
| ExamExplorePage | 全量替换，排序栏保持外部，列表体用组件 |
| PreferenceListPage | 全量替换，用 GlobalKey 支持删除/编辑后刷新 |

### 未迁移页面说明

| 页面 | 原因 | 建议 |
|------|------|------|
| RecommendPage | 双模式（智能/偏好），逻辑复杂 | 保持现有代码，已修复 `refresh()` 不完整问题 |
| HomeworkListPage | cache-then-network 特殊模式 | 保持现有代码 |
| StatisticsPage | 5 路并行 Future.wait | 保持现有代码 |
| IndexPage | 非列表页，Dashboard 布局 | 已修复 `_pageKey++` 问题，无需迁移 |
| ProfilePage | 非列表页，复杂布局 | 已修复多余重载问题，无需迁移 |

---

## 阶段二：修复不合理的刷新模式 ✅ 全部完成

### P0-1: IndexPage `_pageKey++` 强制重建 ✅

**改动文件**: `main_shell.dart`、`index_page.dart`

- `_IndexPageState` → `IndexPageState`（公开，添加 `reload()` 方法）
- `ValueKey('index_$_pageKey')` → `GlobalKey<IndexPageState>`
- Tab 切换 `setState(() => _pageKey++)` → `_indexKey.currentState?.reload()`
- `_onDbVersionChanged` 同理改用 `reload()`
- 删除 `_pageKey` 字段

**收益**: 切回首页 Tab 不再丢失滚动位置和 `_showWelcomeHint` 本地状态

### P0-2: LectureCourses/Chapters 虚假下拉刷新 ✅

**改动文件**: `lecture_courses_page.dart`、`lecture_chapters_page.dart`

- 移除两个页面的 RefreshIndicator 包裹

**原由**: 讲义数据只通过 `UpdateManager.replaceCoursesDb()` + `dbVersionNotifier` 更新。用户手动下拉永远读同一个本地 DB，不会刷出新内容。且这两个页面通过导航进入（不在 IndexedStack），每次进入 `initState` 已读取最新数据。

### P1-3: RecommendPage.refresh() 不完整 ✅

**改动文件**: `recommend_page.dart`

- `refresh()` 原来只加载偏好预设列表（`_repo.getPresets()`）
- 改为调用 `_loadSilent()`，同步加载预设 + 智能推荐题目（不显示 loading 指示器，避免切 Tab 闪烁）
- 智能模式下刷新题目列表，偏好模式下只刷预设列表

### P2-4: ProfilePage 关于页返回多余重载 ✅

**改动文件**: `profile_page.dart`

- 移除 `await context.push(AppRoutes.profileAbout); reload();` 
- 改为 `() => context.push(AppRoutes.profileAbout)`

**原由**: AboutPage 的更新操作已触发 `dbVersionNotifier` → `_onDbVersionChanged` → `_profileKey.currentState?.reload()`，无需冗余调用

---

## 阶段三：统一 `pushAndRefresh` 工具方法 ⏳ 待执行

### 现状

6 处使用 `await context.push(...); _loadKey.currentState?.refresh();` 模式：

| 位置 | 模式 |
|------|------|
| ProfilePage 编辑资料 | `_load()` |
| PreferenceListPage 创建/编辑 | `_loadKey.currentState?.refresh()`（已用 GlobalKey） |
| SolveChoicePage onRate | `_load()` |
| SolveMapPage 步骤导航 | `_load()` |
| ExamHistoryPage 删除/切换公开 | `_loadKey.currentState?.refresh()`（已用 GlobalKey） |

### 建议方案

保持现状，不是高优先级——每个页面的刷新触发点都是业务特定的（删除后刷新、编辑后刷新），抽取后反而增加间接性。

---

## 文件清单

| 文件 | 状态 | 改动说明 |
|------|------|---------|
| `widgets/shared/async_load_widget.dart` | 🆕 新增 | 泛型异步加载组件 |
| `pages/main_shell.dart` | ✏️ 修改 | _pageKey → GlobalKey<IndexPageState> |
| `pages/index_page.dart` | ✏️ 修改 | State 公开 + reload() 方法 |
| `pages/recommend_page.dart` | ✏️ 修改 | refresh() 补齐加载全部数据 |
| `pages/profile/profile_page.dart` | ✏️ 修改 | 移除 About 返回后多余 reload() |
| `pages/lecture/lecture_courses_page.dart` | ✏️ 修改 | 移除 RefreshIndicator |
| `pages/lecture/lecture_chapters_page.dart` | ✏️ 修改 | 移除 RefreshIndicator |
| `pages/exam/exam_history_page.dart` | ✏️ 重写 | AsyncLoadWidget 化 |
| `pages/exam/exam_favorites_page.dart` | ✏️ 重写 | AsyncLoadWidget 化 |
| `pages/exam/exam_explore_page.dart` | ✏️ 重写 | AsyncLoadWidget 化 |
| `pages/profile/preference_list_page.dart` | ✏️ 重写 | AsyncLoadWidget 化 |
