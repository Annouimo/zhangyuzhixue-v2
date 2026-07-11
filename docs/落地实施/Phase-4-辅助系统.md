# Phase 4 — 辅助系统（2 天，每步测）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 4 的细化执行方案。
> 状态：**待开始** | 最后更新：2026-07-11

---

## 总览

| 子步骤 | 内容 | 工时 | 测试内容 | 状态 |
|:-------|:-----|:-----|:---------|:----:|
| **4.1** | 成就引擎（_AchievementEngine 补全 + 测试） | 0.3 天 | L1 算法单元 | ⬜ |
| **4.2** | 积分系统（_PointsCalculator 补全 + 积分流水页） | 0.5 天 | L1 算法单元 | ⬜ |
| **4.3** | 退出页面评价弹层（20% 概率 + 24h 冷却） | 0.5 天 | Widget 测试 | ⬜ |
| **4.4** | 同步队列状态页面 | 0.2 天 | Widget 测试 | ⬜ |
| **4.5** | 首次引导流程（preference_welcome → 创建偏好） | 0.5 天 | Widget 测试 | ⬜ |
| | **合计** | **~2 天** | | |

### 前置条件

- [ ] Phase 3 UI 全部完成并验收通过（教师 UAT 签收）
- [ ] 以下 Repository 已在 Phase 2.4 就绪：
  - `AchievementRepository`（含 `_AchievementEngine`）
  - `UserRepository`（含 `_PointsCalculator`）
  - `PreferenceRepository`（CRUD 完整）
  - `SyncRepository`（队列查询快捷方法）

> Phase 4 不涉及服务端改动。成就/积分/偏好全部走本地 user.db 计算，评价弹层数据通过 SyncApi 入队上传。

### 关键设计文档索引

| 文档 | 用途 |
|:-----|:------|
| [`页面设计说明.md`](../04-UI/页面设计说明.md) §6 | 退出页面评价交互规范 |
| [`docs/04-UI/html/preference_welcome.html`](../04-UI/html/preference_welcome.html) | 首次引导流程原型 |
| [`docs/04-UI/html/preference_edit.html`](../04-UI/html/preference_edit.html) | 偏好编辑页原型（复用 4.5） |
| [`docs/04-UI/html/preference_list.html`](../04-UI/html/preference_list.html) | 偏好管理列表原型（Phase 3 已含） |
| [`docs/04-UI/html/sync_queue.html`](../04-UI/html/sync_queue.html) | 同步队列状态页原型 |
| [`Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | Widget 组织、Prefs 前缀 |
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) §5.7 | 成就表定义 |
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) §5.4 | 积分流水表定义 |

---

## 4.1 — 成就引擎补全 + 测试（0.3 天）

### 现状分析

`_AchievementEngine` 已在 Phase 2.4 实现，位于 `achievement_repository.dart` 文件尾部。当前支持的 triggerType：

| triggerType | 当前实现 | 状态 |
|:------------|:---------|:----:|
| `LOGIN_STREAK` | `_dao.getLoginStreak()` | ✅ |
| `PRACTICE_COUNT` | `_dao.getSubmissionCount()` | ✅ |
| `PAPER_COUNT` | `progress = 0`（标注"需 ExamDao 提供"） | ⚠️ stub |
| `RATING_COUNT` | `_dao.getRatingCount()` | ✅ |

### 涉及文件

```
flutter_app/lib/domain/achievement_repository.dart   # 修改：补全 PAPER_COUNT
flutter_app/test/data/domain/achievement_repository_test.dart  # 修改/新增：覆盖 4 种 trigger
```

### 实现要点

**补全 PAPER_COUNT：**

`_AchievementEngine.compute()` 中 `case 'PAPER_COUNT'` 当前返回 0，需改为从 `ExamDao` 查询 `custom_paper` 数量。

修改方式：给 `AchievementRepository` 增加 `ExamDao` 依赖（构造注入），传递到 `_AchievementEngine`。

```dart
class AchievementRepository {
  final AchievementDao _dao;
  final QuestionDao _questionDao;
  final ExamDao _examDao;  // 新增

  const AchievementRepository(this._dao, this._questionDao, this._examDao);

  Future<List<AchievementCategory>> getCategories() async {
    // ...
    final engine = _AchievementEngine(_dao, _examDao);  // 传 ExamDao
    // ...
  }
}

class _AchievementEngine {
  final AchievementDao _dao;
  final ExamDao _examDao;
  const _AchievementEngine(this._dao, this._examDao);

  Future<AchievementItem> compute(...) async {
    switch (def.triggerType) {
      case 'PAPER_COUNT':
        progress = await _examDao.getPaperCount();  // 从 ExamDao 查询
        break;
      // ...
    }
  }
}
```

> `ExamDao` 当前已有 `getPaperCount()` 方法（见 Phase 2.1 设计），确认存在即可。

**引擎逻辑完善（可选增强）：**
- 当前 `_AchievementEngine.compute()` 不保存 `unlocked_at` 时间戳，只做实时推算——这是设计意图（不存状态，每次都实时算），保持不动

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| `_AchievementEngine` | LOGIN_STREAK：streak=5, threshold=7 | 2 |
| `_AchievementEngine` | PRACTICE_COUNT：计数精确 | 2 |
| `_AchievementEngine` | PAPER_COUNT：从 ExamDao 取值 | 2 |
| `_AchievementEngine` | RATING_COUNT：计数精确 | 2 |
| `_AchievementEngine` | 未知 triggerType → progress=0（容错） | 1 |
| `_AchievementEngine` | 进度条百分比计算（progress=0/过半/满） | 3 |

**合计：~12 个测试用例**

### 注意事项

- `ExamDao` 的 `getPaperCount()` 需要在 `AchievementRepository` 的测试中 mock 或使用 memory DB 插入数据
- 当前 `achievement_repository_test.dart` 只有 67 行，4.1 需要追加针对 4 种 trigger 的测试
- 引擎不保存解锁时间（`unlockedAt=null`），这是设计意图，不需要改

---

## 4.2 — 积分系统补全 + 积分流水页（0.5 天）

### 现状分析

`_PointsCalculator` 已在 Phase 2.4 实现，位于 `user_repository.dart` 文件尾部。当前功能：

| 方法 | 状态 |
|:-----|:----:|
| `earned` | ✅ 3 种来源（LOGIN_BONUS/PRACTICE_REWARD/TASK_REWARD） |
| `bonus` | ✅ SIGNUP_BONUS |
| `spent` | ✅ PAPER_PURCHASE |
| `available` | ✅ earned + bonus - spent |

积分流水页（`points_page.dart`）已在 Phase 3h 的组件清单中。4.2 负责确认引擎完整 + 补上单元测试缺口 + 确保积分流水页正确绑定 data-db。

### 涉及文件

```
flutter_app/lib/domain/user_repository.dart                      # 确认（不改，仅审计）
flutter_app/lib/pages/profile/points_page.dart                    # 确认 data-db 绑定正确（Phase 3h）
flutter_app/test/data/domain/user_repository_test.dart            # 修改/新增：补充积分引擎测试
```

### 实现要点

**确认 points_page.dart 的 data-db 绑定（来自 HTML 原型 `points.html`）：**

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 可用积分 | `data-db="user.getInfo.pointsSummary.available"` | 大数字显示 |
| 获得积分 | `data-db="user.getInfo.pointsSummary.earned"` | — |
| 赠送积分 | `data-db="user.getInfo.pointsSummary.bonus"` | — |
| 消费积分 | `data-db="user.getInfo.pointsSummary.spent"` | — |
| 积分流水列表 | `data-db-loop="user.getInfo.pointsHistory"` | 时间倒序 |
| 列表项 | `data-db="user.getInfo.pointsHistory[].time"` / `.type` / `.change` | — |

**积分引擎测试覆盖——四个汇总维度：**

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| `_PointsCalculator.earned` | 仅 LOGIN_BONUS / 混合来源 / 无数据 | 3 |
| `_PointsCalculator.bonus` | 有 SIGNUP_BONUS / 无 | 2 |
| `_PointsCalculator.spent` | 有 PAPER_PURCHASE / 无 | 2 |
| `_PointsCalculator.available` | earned + bonus - spent 公式正确 | 2 |
| `_PointsCalculator` | 空列表（所有值均为 0） | 1 |

**合计：~10 个测试用例（可能有些已存在，确认后补缺即可）**

### 注意事项

- 积分流水页是**只读页面**，积分由引擎自动累计，无手动操作
- `todayEarned()`（第 177 行）、`todayReward()` / `nextReward()`（第 201–205 行）当前为 stub（返回 0），但不在 Phase 4 范围内——这些是签到相关，列在 backlog 中待后续补充
- 积分数据不走 sync（纯本地累计，不依赖服务端）

---

## 4.3 — 退出页面评价弹层（0.5 天）

### 涉及文件

```
flutter_app/lib/widgets/
└── exit_rating_popup.dart         # 新建：退出评价弹层

# 触发方（需在各页面添加退出时判断）
# 在 solve_choice/fill/step_page 的 back 按钮、exam_quicklook_page 的 back、
# lecture_content_page 的 back 中各加判断
```

### 实现要点

**触发规则（来自页面设计说明 §6）：**

| 规则 | 值 | 默认 | 配置方式 |
|:-----|:---|:-----|:---------|
| 触发概率 | 20% | `SYSTEM_PARAM_EXIT_RATING_PROBABILITY` | SystemConfig |
| 同页冷却 | 24h | `SYSTEM_PARAM_EXIT_RATING_COOLDOWN_HOURS` | SystemConfig |
| 停留阈值 | >30s | `SYSTEM_PARAM_EXIT_RATING_MIN_STAY_SECONDS` | SystemConfig |

**触发页面：** `solve-choice` / `solve-fill` / `solve-step` / `exam_quicklook` / `lecture_content`

**弹层内容：**

```
┌──────────────────────────────┐
│     🎉 感觉怎么样？           │
│                              │
│     😡  😕  😐  😊  🤩       │  ← 5 级表情评分
│                              │
│  [输入框：说说你的想法...]    │  ← 可选文字反馈
│                              │
│  [提交反馈 (+5 积分)]        │
│  [跳过]                      │
└──────────────────────────────┘
```

**实现流程（完整版）：**

```dart
/// 检查是否应该显示评价弹层
bool shouldShowRating(String pageUrl) {
  // 1. 概率检查：Random().nextDouble() < _ratingProbability
  if (Random().nextDouble() >= ratingProbability) return false;

  // 2. 冷却检查：isRatingCooldownActive(pageUrl) → AppPrefs
  if (AppPrefs().isRatingCooldownActive(pageUrl)) return false;

  // 3. 停留时间检查：从页面打开到退出 >= minStaySeconds
  if (elapsedSeconds < minStaySeconds) return false;

  return true;
}

/// 提交评价
Future<void> submitRating(int score, String? feedback) async {
  // 1. 设置冷却（AppPrefs.setRatingCooldown(pageUrl)）
  await AppPrefs().setRatingCooldown(pageUrl);

  // 2. 推送评分数据到 sync 队列
  await SyncManager().enqueue(
    entityType: 'exit_rating',
    operation: 'create',
    payload: {'score': score, 'feedback': feedback, 'page_url': pageUrl},
  );

  // 3. 赠送积分（写入 points_transaction 表）
  // (通过 UserRepository 或直接通过 PointsDao)
}
```

**参数来源：** `ratingProbability` / `minStaySeconds` 从 `SystemConfig` 读取（服务端配置的冷却时长/概率等），客户端开发阶段先用默认硬编码值，后续通过 DB 版本更新同步配置。

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| 触发条件 | 概率通过 + 冷却未过 + 停留足够 → 显示 | 2 |
| 触发条件 | 冷却未过 → 不显示 | 1 |
| 触发条件 | 停留不足 → 不显示 | 1 |
| 弹层交互 | 5 级表情可选、文字可输入 | 2 |
| 提交流程 | 提交→冷却写入 + sync 入队 + 积分赠送 | 3 |
| 跳过 | 点击跳过→弹层消失，不设冷却 | 1 |

**合计：~10 个测试用例**

### 注意事项

- 冷却机制在 `AppPrefs` 中已有 `isRatingCooldownActive` / `setRatingCooldown` 实现（Phase 2.3），直接复用
- 停留时间测量：在页面 initState 记录 `DateTime.now()`，在退出时算 diff
- 弹层用 `showDialog` 弹出，背景半透明不可操作
- 评价不是用户必填——5 级评分必选，文字反馈可选
- 触发规则中 SystemConfig 的三个参数在服务端定义，客户端构建脚本尚未同步这些配置到 assets.db。**临场方案：** 4.3 先用硬编码常量兜底（`exit_rating.dart` 中一个 `_RatingConfig` 类），线上 DB 版本稳定后再抽入 SystemConfig

---

## 4.4 — 同步队列状态页面（0.2 天）

### 涉及文件

```
flutter_app/lib/pages/
└── sync_queue_page.dart           # 新建：同步队列状态页
```

### 实现要点

来自 HTML 原型 `sync_queue.html`：

**页面布局：**

```
[← 返回]  同步状态

[🔄 全部重试]   ← 仅在 hasFailed=true 时显示

条目列表：
┌─────────────────────────────┐
│ 📝 提交答案    🔄 重试      │  ← 失败项显示重试按钮
│ 2 分钟前                     │
│ 状态：等待同步                │
├─────────────────────────────┤
│ ⭐ 评分         ⌛ 等待中    │
│ 5 分钟前                     │
│ 状态：等待同步                │
└─────────────────────────────┘
```

**data-db 绑定：**

| 元素 | data-db | 说明 |
|:-----|:--------|:-----|
| 全部重试按钮 | `data-db-show="sync.hasFailed"` | 仅在有失败项时显示 |
| 全部重试 | `data-db-action="sync.retryAll()"` | → SyncRepository.retryAll |
| 同步列表 | `data-db-loop="sync.getQueue"` | — |
| 图标 | `data-db="sync.getQueue[].icon"` | 📝/⭐/📄 等 |
| 操作名 | `data-db="sync.getQueue[].entityTypeName"` | "提交答案"/"评分" 等 |
| 时间 | `data-db="sync.getQueue[].timeAgo"` | "2 分钟前" |
| 状态 | `data-db="sync.getQueue[].statusDisplay"` | "等待同步"/"同步失败" |

**SyncRepository 需补充的方法（确认或补全）：**

| 方法 | 当前状态 | 用途 |
|:-----|:---------|:-----|
| `getQueue()` | ✅ Phase 2.4 | 获取全量队列 |
| `hasFailed()` | ⬜ | 是否有失败项（查询 retryCount>0 或 status=failed） |
| `retryAll()` | ⬜ | 重置所有失败项为 pending |

**数据源：** `SyncQueueDao` — `getPending()` 获取待处理项，`markFailed` / `markSuccess` 由 `SyncPusher` 调用。

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| 队列列表 | 有空项/有失败项/全成功 | 3 |
| hasFailed | 有失败项/无失败项 | 2 |
| retryAll | 重置失败项为 pending | 1 |
| UI 状态 | 等待中/同步失败 样式正确 | 2 |

**合计：~8 个测试用例**

### 注意事项

- 同步队列页面是**诊断性页面**（非教学核心功能），UI 可以简朴
- `timeAgo` 显示：用当前时间减 `created_at`，显示「N 分钟前」「N 小时前」「N 天前」。简单实现即可，不需要第三方包
- 路由：从「我的」页进入（`/sync/queue`），HTML 原型是 `sync_queue.html`，入口在 `profile.html` 底部的「同步状态」链接

---

## 4.5 — 首次引导流程（0.5 天）

### 涉及文件

```
flutter_app/lib/pages/
├── preference_welcome_page.dart   # 新建：首次引导页（弹窗+表单）
├── preference_edit_page.dart      # 新建：偏好编辑页（复用原有设计，Phase 3h 列表入口已有）
```

### 实现要点

**触发时机：** 登录/注册成功后 → 检查 `preference.count` → 0 则跳转 `preference_welcome_page`。

**页面流程（来自 HTML 原型 `preference_welcome.html`）：**

```
1. 注册/登录成功
    ↓
2. 检查 preference.count == 0?
    ├── 否 → 正常跳 MainShell/首页
    └── 是 → 弹出欢迎弹窗
3. 欢迎弹窗（全屏半透明遮罩）:
   🎉 "欢迎加入章鱼智学！"
   +10 赠送积分（显示数字）
   "可用于组卷等消费功能"
   [👌 开始设置学习偏好]   ← 用户点击
    ↓
4. 选择偏好表单页（同 preference_edit_page 布局）:
   - 偏好名称（默认"我的偏好"）
   - 筛选条件（年份/地区/考试/概念标签/难度）
   [💾 保存偏好]   ← 用户点击
    ↓
5. 保存成功后自动跳转 MainShell/首页
```

**与 PreferenceRepository 的绑定：**

| data-db | Repository 方法 |
|:--------|:---------------|
| `data-db-action="preference.create()"` | `PreferenceRepository.create(filter)` |
| `data-db="preference.welcome.bonusPoints"` | `_PointsCalculator.bonus` 的注册赠送分 |
| `data-db-bind="preference.welcome.name"` | `PreferenceFilter.name` |

**页面内 FilterPanel 复用：** 筛选条件部分复用 Phase 3e 的 `FilterPanel` 组件（年份/地区/考试多选胶囊 + 难度滑块），但 `preference_welcome` 的筛选面板是简化版（只设一次，不要求像组卷那样精细）。

**登录后跳转判断逻辑（在 login_page.dart / register_page.dart 中）：**

```dart
Future<void> onLoginSuccess() async {
  final prefRepo = PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
  final count = await prefRepo.getCount();
  if (count == 0) {
    // 跳转到 preference_welcome_page（首次引导）
    Navigator.pushReplacementNamed(context, '/preference/welcome');
  } else {
    // 正常跳转 MainShell
    Navigator.pushReplacementNamed(context, '/');
  }
}
```

### 验证方式

| 测试 | 场景 | 数量 |
|:-----|:-----|:----:|
| 引导触发 | 注册成功 + count=0 → 弹窗显示 | 2 |
| 引导跳过 | count>0 → 不弹窗，直接进 MainShell | 1 |
| 欢迎弹窗 | 关闭 → 偏好表单显示 | 1 |
| 表单提交 | 填写名称+筛选条件 → 保存成功 → 跳首页 | 2 |
| 表单提交 | 空名称筛选 → 保存失败提示 | 1 |
| 筛选用例 | 年份/地区/概念标签/难度全部可选 | 2 |
| 返回处理 | 用户直接关闭弹窗 → 跳首页 | 1 |

**合计：~10 个测试用例**

### 注意事项

- 引导流程只在**首次**出现——`AppPrefs` 中已有 `firstLaunchComplete` key（Phase 2.3），可辅助判断
- 引导页不涉及服务端——所有偏好数据存入本地 user.db 的 `preference_filter` 表
- 欢迎弹窗中显示的「+10 赠送积分」是注册赠送的 `SIGNUP_BONUS`，无需在引导页再触发一次（注册时已写入）
- 偏好编辑页（`preference_edit_page.dart`）在 Phase 3h 的 preference_list 入口已有，引导页和编辑页共享同一个 PreferenceRepository 和 FilterPanel，不要重复实现
- 路由：`/preference/welcome`

---

## 测试汇总

| 子步骤 | 测试数 |
|:-------|:------:|
| 4.1 成就引擎 | ~12 |
| 4.2 积分系统 | ~10 |
| 4.3 退出评价弹层 | ~10 |
| 4.4 同步队列状态 | ~8 |
| 4.5 首次引导流程 | ~10 |
| **合计** | **~50** |

> 测试嵌入到每个子步骤中。4.1/4.2 为 L1 算法单元测试，4.3–4.5 为 Widget 测试。

---

## 路由表追加

| 路径 | 页面 | 所属子步骤 |
|:-----|:-----|:----------|
| `/sync/queue` | SyncQueuePage | 4.4 |
| `/preference/welcome` | PreferenceWelcomePage | 4.5 |
| `/preference/edit` | PreferenceEditPage | 4.5（已有，确认即可） |

---

## 验收标准

1. 4 种成就 triggerType（LOGIN_STREAK / PRACTICE_COUNT / PAPER_COUNT / RATING_COUNT）全部可通过测试验证
2. `_PointsCalculator` 四个维度（earned / bonus / spent / available）的计算公式正确
3. 积分流水页从 user.db 读取 PointsTransaction 并正确展示
4. 退出评价弹层在目标页面回退时**可能**触发（概率 20%），触发后 5 级表情评分可交互
5. 评价提交后冷却写入 AppPrefs，24h 内同一页不再弹
6. 同步队列状态页展示队列条目，失败项可「全部重试」
7. 首次引导流程在注册后 count=0 时弹出，填写保存后跳转首页
8. 所有 ~50 个测试全部通过
