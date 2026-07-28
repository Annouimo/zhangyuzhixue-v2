# Phase 2.4 — 13 个 Repository 全部实现

> 本文档是 [Phase-2-Flutter数据层.md](./Phase-2-Flutter数据层.md) 中 2.4 子步骤的细化执行方案。
> 状态：**已完成** | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **2.4** | 13 个 Repository 全部实现 | 1.5 天 | ✅ |

### 前置条件

- [x] Phase 2.1 完成：3 个 DAO 组（11 个 DAO）就绪
- [x] Phase 2.2 完成：DatabaseProvider + ApiClient 就绪
- [x] Phase 2.3 完成：AppPrefs + ConnectivityMonitor 就绪
- [x] `docs/05-Flutter/Repository/*.dart` 13 个设计稿已审阅

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`docs/05-Flutter/Repository/*.dart`](../05-Flutter/Repository/) | 13 个 Repository 接口设计稿 |
| [`数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | Repository→DAO 层间契约 |
| [`Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | Repository 规范 |
| [`flutter_app/lib/domain/`](../../flutter_app/lib/domain/) | 实现文件目录 |

---

## 2.4 — 13 个 Repository 全部实现

### 涉及文件

```
flutter_app/lib/domain/
├── auth_repository.dart
├── question_repository.dart
├── exam_repository.dart
├── progress_repository.dart
├── assignment_repository.dart
├── lecture_repository.dart
├── user_repository.dart
├── rating_repository.dart
├── recommend_repository.dart
├── statistics_repository.dart
├── preference_repository.dart
├── achievement_repository.dart
├── sync_repository.dart
└── domain.dart                # barrel export
```

### 实现要点

#### 2.4.1 — 实现方式

将 `docs/05-Flutter/Repository/*.dart` 设计稿复制到 `lib/domain/`，并替换 `throw UnimplementedError` 为真实实现。

**三个变更要点：**
1. 设计稿中大部分方法是 `static`——**改为实例方法**（构造注入 DAO）
2. 去掉 `fromJson`（Repository 从本地 DB 读数据，不从 API 反序列化）
3. 补充 import 和依赖注入

#### 2.4.2 — 依赖注入清单

| Repository | 依赖的 DAO | 依赖的 API | 尾部算法类 |
|------------|-----------|-----------|-----------|
| AuthRepository | — | AuthApi | — |
| QuestionRepository | QuestionDao | — | — |
| ExamRepository | QuestionDao + ExamDao | UserApi(同步) | `_ExamFilterEngine` + `_ExamGenerator` |
| ProgressRepository | ProgressDao | SyncApi(入队) | — |
| AssignmentRepository | AssignmentDao | — | — |
| LectureRepository | LectureDao | — | — |
| UserRepository | UserDao | UserApi | `_PointsCalculator` |
| RatingRepository | RatingDao | SyncApi(入队) | — |
| RecommendRepository | QuestionDao + ProgressDao | — | `_RecommendationEngine` |
| StatisticsRepository | StatisticsDao | — | `_StatisticsAggregator` |
| PreferenceRepository | PreferenceDao | — | — |
| AchievementRepository | AchievementDao | — | `_AchievementEngine` |
| SyncRepository | SyncQueueDao | SyncApi | — |

#### 2.4.3 — Repository 构造方式

全量构造注入，无 DI 框架：

```dart
// auth_repository.dart
class AuthRepository {
  final AuthApi _api;
  const AuthRepository(this._api);

  Future<LoginResult> login(LoginRequest request) async { ... }
  Future<void> register(RegisterRequest data) async { ... }
  Future<RefreshResult> refresh(String refreshToken) async { ... }
}

// exam_repository.dart
class ExamRepository {
  final QuestionDao _questionDao;
  final ExamDao _examDao;
  final UserApi _userApi;

  const ExamRepository(this._questionDao, this._examDao, this._userApi);

  Future<List<ExploreExamSummary>> getExploreList() async { ... }
  Future<PoolStats> getPoolStats(SearchFilters filters) async {
    return _ExamFilterEngine(_questionDao).compute(filters);
  }
  Future<int> confirm(SearchFilters filters, {bool allowShortfall = false}) async {
    return _ExamGenerator(_questionDao, _examDao).confirm(filters, allowShortfall: allowShortfall);
  }
}
```

#### 2.4.4 — 5 个尾部算法类的实现要求

| 算法类 | 所属 Repository | 核心代码行数估算 |
|--------|----------------|-----------------|
| `_PointsCalculator` | UserRepository | ~50 行 |
| `_ExamFilterEngine` | ExamRepository | ~40 行 |
| `_ExamGenerator` | ExamRepository（含 300+ 行算法描述） | ~120 行 |
| `_RecommendationEngine` | RecommendRepository | ~100 行 |
| `_StatisticsAggregator` | StatisticsRepository | ~80 行 |

**合计算法代码：~390 行**

### 验证方式

每个 Repository 写集成测试（DAO + memory DB 或 mock DAO）：

| Repository | 测试重点 | 最少数 |
|-----------|---------|-------|
| AuthRepository | login/register/refresh 调用结果解析 | 4 |
| QuestionRepository | getDetail 组合数据、getAttempts、nextQuestion | 4 |
| ExamRepository | getExploreList/favorites、getPoolStats（委托 Engine） | 6 |
| ExamRepository.confirm | 正常组卷、池子不足抛异常、allowShortfall | 4 |
| ProgressRepository | getSolveState、createAttempt/submitStepFeedback | 5 |
| AssignmentRepository | getPending、getQuestions、pendingCount | 3 |
| LectureRepository | getCourses、getChapters、getContent（含 parseMdContent） | 5 |
| UserRepository | getUserInfo、saveProfile、points 汇总方法 | 5 |
| RatingRepository | getRating、submitRating | 2 |
| RecommendRepository | 冷启动返回空、getSmartList 推荐结果 | 4 |
| StatisticsRepository | getOverview、getDailyRecords、getDistribution | 4 |
| PreferenceRepository | CRUD 完整流程 | 3 |
| AchievementRepository | getSummary、getCategories | 3 |
| SyncRepository | getQueue、getFailedCount 等快捷方法 | 3 |

**合计：~55 个测试用例**

**尾部算法类单独测：**

| 私有类 | 关键场景 | 测试数 |
|--------|---------|-------|
| `_ExamFilterEngine.compute` | 空池、正常统计、无对应题型 | 3 |
| `_ExamGenerator.confirm` | 正常组卷（贪心+交换3轮）、池子不足、allowShortfall | 5 |
| `_RecommendationEngine` | 冷启动（<5 条记录）、路线A（概念掌握度）、路线B（卡片卡住率）、边界 | 6 |
| `_StatisticsAggregator` | 7 天记录、30 天降采样、无数据 | 3 |
| `_PointsCalculator` | earned/bonus/spent/available 四种汇总、无数据 | 3 |

**合计：~20 个测试用例**

### 操作清单

1. 在 `lib/domain/` 下创建 13 个 Repository 文件
2. 每个文件：复制设计稿 + 替换 UnimplementedError + 改 static 为实例方法 + 构造注入
3. 对 5 个尾部算法类逐一实现算法逻辑
4. 编写 Repository 集成测试（memory DB）
5. 编写尾部算法类单元测试
6. `flutter test` 全部通过

### 注意事项

- Repository 方法从设计稿的 `static` 改为实例方法后，注意同步修改所有调用处（主要是测试文件）
- `_ExamGenerator` 的组卷算法包含约 300 行逻辑（贪心选 + 交换 3 轮），单元测试需覆盖边界情况
- `_RecommendationEngine` 冷启动（<5 条记录）应返回空列表而非全量，避免给新用户推荐无关内容
- 尾部算法类通过 Repository 的公有方法间接测试，不暴露私有类
