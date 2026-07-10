# Phase 2 — Flutter 数据层（4.5 天，每步测）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 2 的细化执行方案。
> 状态：**未开始** | 计划日期：2026-07-11 | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **2.1** 🔧CI | 3 个 Drift Database（assets/lectures/user）+ 11 个 DAO | 1.5 天 | ⬜ |
| **2.2** | DatabaseProvider（生命周期）+ ApiClient（3 拦截器） | 0.5 天 | ⬜ |
| **2.3** | AppPrefs + ConnectivityMonitor | 0.5 天 | ⬜ |
| **2.4** | 13 个 Repository 全部实现 | 1.5 天 | ⬜ |
| **2.5** | 同步引擎 + 更新机制 | 1 天 | ⬜ |
| | **合计** | **~4.5 天** | |

### 前置条件

- [ ] 服务端已部署到 staging（Phase 1.5），API 端点可用
- [ ] Flutter SDK（3.44+）和 Drift 环境就绪
- [ ] 已读取 `docs/02-数据/数据库结构设计.md` 全部表定义
- [ ] 已读取 `docs/05-Flutter/` 下所有 Repository 设计稿（13 个文件）

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`docs/02-数据/数据库结构设计.md`](../02-数据/数据库结构设计.md) | 所有表定义（assets + user） |
| [`docs/05-Flutter/Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | 目录结构、Repository 规范、Widget 复用 |
| [`docs/05-Flutter/数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | DAO→Database、Repository→DAO 层间契约 |
| [`docs/05-Flutter/同步引擎设计.md`](../05-Flutter/同步引擎设计.md) | 同步队列状态机 + 重试策略 |
| [`docs/05-Flutter/Repository/*.dart`](../05-Flutter/Repository/) | 13 个 Repository 接口 + 数据模型定义 |
| [`docs/05-Flutter/sync/*.dart`](../05-Flutter/sync/) | 同步引擎 4 个 Dart 设计稿 |
| [`docs/02-数据/更新机制.md`](../02-数据/更新机制.md) | 版本号体系与启动流程 |
| [`docs/02-数据/构建脚本设计.md`](../02-数据/构建脚本设计.md) | assets.db/lectures.db 表结构定义 |
| [`docs/02-数据/本地数据架构.md`](../02-数据/本地数据架构.md) | 三库方案和网络失败处理 |
| [`docs/05-Flutter/数据访问层设计.md`](../05-Flutter/数据访问层设计.md) §四 | DAO/Repository 测试规范 |

### 当前 Flutter 端状态

```
flutter_app/lib/
├── main.dart              # 仅骨架（显示"章鱼智学 v2"文字）
├── pubspec.yaml           # ✅ 依赖已定义（drift, dio, riverpod 等）
└── test/widget_test.dart  # 1 个占位测试
```

**本次 Phase 2 目标：从只有 main.dart 的骨架状态 → 完整的 data/domain 层就绪，使 Phase 3 可以直接写 UI。**

### 🔧CI 更新说明

| 子步骤 | CI 变更 |
|--------|---------|
| **2.1** | CI 中 Flutter job 的 `flutter test` 开始包含 DAO 测试（memory DB + CRUD）。配置已就位无需改动；可选加测试报告上传增强可读性 |
| **2.2–2.5** | CI 无变更，增量测试已在 `flutter test` 中覆盖 |

---

## 2.1 — 3 个 Drift Database + 11 个 DAO（1.5 天）

### 涉及文件

```
flutter_app/lib/data/database/
├── assets_database.dart          # assets.db（只读，镜像服务端题库结构）
├── lectures_database.dart        # lectures.db（只读，镜像服务端讲义结构）
├── app_database.dart             # user.db（读写，用户数据 + 同步队列）
├── database_provider.dart        # （创建于 2.2，本步骤只声明）
└── *.g.dart                      # Drift 代码生成

flutter_app/lib/data/daos/
├── question_dao.dart             # assets 库：题目查询 + 筛选
├── assignment_dao.dart           # assets 库：作业查询
├── lecture_dao.dart              # lectures 库：课程/章节/讲义
├── progress_dao.dart             # user 库：submission_detail + step_feedback + card_feedback
├── rating_dao.dart               # user 库：question_rating
├── preference_dao.dart           # user 库：preference_filter
├── sync_queue_dao.dart           # user 库：同步队列
├── achievement_dao.dart          # user 库：student_achievement + 成就进度查询
├── statistics_dao.dart           # user + assets 库：统计查询（跨表）
├── exam_dao.dart                 # user + assets 库：custom_paper + paper_question
└── user_dao.dart                 # user 库：user_profile + points_transaction
```

### 2.1.1 — Drift Database 定义

#### 原则

- 表定义严格参照 `docs/02-数据/数据库结构设计.md` 和 `docs/02-数据/构建脚本设计.md` 中的 `ASSETS_TABLES`/`LECTURE_TABLES`
- 用户表（user.db）参考数据库结构设计 §5–§7
- 镜像原则：assets/lectures 库表结构与服务端 Django 一致，差异仅换行/格式/本地特有字段

#### assets_database.dart

**位置：** `lib/data/database/assets_database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// 所有 assets 表定义

@DataClassName('QuestionRow')
class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();  // 注意：autoIncrement 但实际用服务端 ID
  IntColumn get year => integer()();
  TextColumn get examType => text()();
  TextColumn get region => text()();
  TextColumn get number => text()();
  TextColumn get questionType => text()();
  RealColumn get difficulty => real().nullable()();
  RealColumn get calculation => real().nullable()();
  TextColumn get stem => text()();
  TextColumn get images => text().nullable()();  // JSON list
  RealColumn get defaultScore => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ChoiceExt — options JSON
@DataClassName('ChoiceExtRow')
class ChoiceExt extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer().unique()();
  TextColumn get options => text()();  // JSON {"A":"...","B":"...",...}
}

// SubQuestion
@DataClassName('SubQuestionRow')
class SubQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn? get parentId => integer().nullable()();
  TextColumn? get stem => text().nullable()();
  TextColumn? get answer => text().nullable()();
  IntColumn get sortOrder => integer()();
}

// SolutionMethod
@DataClassName('SolutionMethodRow')
class SolutionMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subQuestionId => integer()();
  TextColumn? get methodName => text().nullable()();
  TextColumn? get source => text().nullable()();
  IntColumn get sortOrder => integer()();
}

// SolutionStep
@DataClassName('SolutionStepRow')
class SolutionSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get methodId => integer()();
  IntColumn get stepNumber => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn? get cardTitles => text().nullable()();  // JSON list
}

// ConceptTag
@DataClassName('ConceptTagRow')
class ConceptTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn? get parentId => integer().nullable()();
}

// KnowledgeCard
@DataClassName('KnowledgeCardRow')
class KnowledgeCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get content => text()();
}

// 中间表
@DataClassName('QuestionConceptTagRow')
class QuestionConceptTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get conceptTagId => integer()();
}

@DataClassName('QuestionKnowledgeCardRow')
class QuestionKnowledgeCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get knowledgeCardId => integer()();
}

// 成就定义
@DataClassName('AchievementDefRow')
class AchievementDefs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
  TextColumn? get icon => text().nullable()();
  TextColumn? get iconEmoji => text().nullable()();
  TextColumn get category => text()();
  TextColumn? get categoryLabel => text().nullable()();
  IntColumn? get displayOrder => integer().nullable()();
  TextColumn? get triggerType => text().nullable()();
  IntColumn? get threshold => integer().nullable()();
}

// 等级配置
@DataClassName('LevelConfigRow')
class LevelConfigs extends Table {
  IntColumn get level => integer()();
  IntColumn get minXp => integer()();
  TextColumn get title => text()();
  TextColumn? get iconEmoji => text().nullable()();

  @override
  Set<Column> get primaryKey => {level};
}

// _meta 表（内建构建元数据）
class Meta extends Table {
  IntColumn get schemaVersion => integer()();
  IntColumn get dataVersion => integer()();
  TextColumn get checksum => text()();
  TextColumn get builtAt => text()();
}

@DriftDatabase(tables: [
  Questions,
  ChoiceExt,
  SubQuestions,
  SolutionMethods,
  SolutionSteps,
  ConceptTags,
  KnowledgeCards,
  QuestionConceptTags,
  QuestionKnowledgeCards,
  AchievementDefs,
  LevelConfigs,
  Meta,
])
class AssetsDatabase extends _$AssetsDatabase {
  AssetsDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

> **注意：** 以上是 11 个表。当前 assets.db 构建脚本中 `ASSETS_TABLES` 定义了 14 个表（含 course / assignment / assignment_question 三个课程相关表）。**这三个表同时存在于 assets.db 和 lectures.db**，但只通过 lectures.db 读取。assets_database.dart 中可省略 course/assignment/assignment_question 这三个冗余表，如果构建脚本生成的 assets.db 包含它们，就保留以保持兼容。

#### lectures_database.dart

**位置：** `lib/data/database/lectures_database.dart`

表清单：course, chapter, lecture_content, assignment, assignment_question

```dart
@DataClassName('CourseRow')
class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
}

@DataClassName('ChapterRow')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer()();
  IntColumn get index => integer()();
  TextColumn get title => text()();
}

@DataClassName('LectureContentRow')
class LectureContents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId => integer().unique()();
  TextColumn get title => text()();
  TextColumn get mdContent => text()();
  TextColumn? get updatedAt => text().nullable()();
}

@DataClassName('AssignmentRow')
class Assignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn? get description => text().nullable()();
  IntColumn? get courseId => integer().nullable()();
}

@DataClassName('AssignmentQuestionRow')
class AssignmentQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assignmentId => integer()();
  IntColumn get questionId => integer()();
  IntColumn get sortOrder => integer()();
}

// _meta 表（同上）
class Meta extends Table { ... }

@DriftDatabase(tables: [
  Courses,
  Chapters,
  LectureContents,
  Assignments,
  AssignmentQuestions,
  Meta,
])
class LecturesDatabase extends _$LecturesDatabase { ... }
```

#### app_database.dart（user.db）

**位置：** `lib/data/database/app_database.dart`

表清单（参照数据库结构设计 §5–§7 的 `[本地用户]` 和 `[镜像]` 标注）：

- user_profile（§5.2）
- user_login_log（§5.3，本地省略 student_id，UNIQUE login_date）
- points_transaction（§5.4，本地省略 student_id）
- student_achievement（§5.7，本地用 achievement_code 关联 assets）
- submission（§6.1，含 server_id）
- submission_detail（§6.2，含 server_id + attempt_number + status）
- step_feedback（§6.3，含 server_id）
- card_feedback（§6.4，含 server_id，card_title 用 title 而非 FK）
- question_rating（§6.5，含 server_id，UNIQUE question_id）
- custom_paper（§6.6，含 server_id）
- custom_paper_question（§6.7）
- paper_like（§6.8，PK = paper_id）
- paper_collect（§6.9，PK = paper_id）
- preference_filter（§6.11）
- sync_queue（§7.3，含 entity_type/entity_id/payload/status/retry_count等）

**共 15 个表。**

#### `build.yaml` 配置（已存在，验证即可）

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sqlite:
            version: 3.35
            modules:
              json1: true
```

运行 `dart run drift_dev build` 生成 `.g.dart` 文件。

### 2.1.2 — 11 个 DAO

#### DAO 通用规则

```dart
class QuestionDao {
  final AssetsDatabase _db;
  const QuestionDao(this._db);

  // 基础 CRUD（大部分由 Drift 自动生成，无需手写——DAO 封装更语义化的查询）
  Future<QuestionRow?> getById(int id) =>
      _db.select(_db.questions)..where((t) => t.id.equals(id)).getSingleOrNull();

  Future<List<QuestionRow>> search({
    List<int>? years,
    List<String>? regions,
    List<String>? conceptTags,
    double? diffMin,
    double? diffMax,
    double? calcMin,
    double? calcMax,
  }) async {
    final query = _db.select(_db.questions);
    // ... 动态拼接 where 子句
    return await query.get();
  }

  /// 获取筛选选项（去重后的 years / regions / conceptTags）
  Future<({List<int> years, List<String> regions, List<String> conceptTags})>
      getFilterOptions() async { ... }

  /// 获取某题型的题目数
  Future<int> countByType(String questionType, {...}) async { ... }
}
```

#### 11 个 DAO 的方法清单

| DAO 文件 | 数据库 | 核心方法 |
|----------|--------|---------|
| `question_dao.dart` | assets | `getById`, `search`, `getFilterOptions`, `countByType`, `getDifficultyRange`, `getGaokaoStats`, `getFilteredPool` |
| `assignment_dao.dart` | assets | `listAll`, `getById`, `getQuestions` |
| `lecture_dao.dart` | lectures | `getAllCourses`, `getChapters`, `getContent`, `searchByKeyword` |
| `progress_dao.dart` | user | `getSubmissions(questionId)`, `createSubmission`, `getDetail(id)`, `getAttempts(questionId)`, `createAttempt`, `getStepFeedbacks`, `insertStepFeedback`, `getCardFeedbacks`, `insertCardFeedback`, `updateSubmissionStatus` |
| `rating_dao.dart` | user | `getRating(questionId)`, `upsertRating` |
| `preference_dao.dart` | user | `listAll`, `getById`, `save(name, filter)`, `delete(id)`, `count` |
| `sync_queue_dao.dart` | user | `enqueue`, `getPending(limit)`, `markInProgress(id)`, `markSuccess(id, serverId)`, `markFailed(id)`, `clearAll`, `cleanup`, `getFailedCount`, `isEmpty`, `hasFailed` |
| `achievement_dao.dart` | user | `getUnlockedCount`, `getAllProgress`, `upsertProgress(code, progress, unlockedAt)`, `getLoginStreak`, `getSubmissionCount`, `getCompletedLectureCount`, `getPaperCount`, `getRatingCount` |
| `statistics_dao.dart` | user+assets | `getDailyRecords(days)`, `getPointsByDay(days)`, `getTypeDistribution`, `getTotalQuestions`, `getAccuracy` |
| `exam_dao.dart` | user+assets | `listCreated`, `listFavorites`, `listExplore`, `getPreview`, `savePaper(questions, title)`, `deletePaper`, `togglePublic`, `toggleLike`, `toggleCollect`, `getQuickAnswers` |
| `user_dao.dart` | user | `getProfile`, `saveProfile`, `getPointsHistory`, `getEarnedPoints`, `getBonusPoints`, `getSpentPoints`, `getTodayPoints`, `getStreakDays`, `getTodayReward`, `getNextReward` |

### 2.1.3 — 测试计划

**类型：** DAO 单元测试（in-memory Drift）

```dart
// question_dao_test.dart
void main() {
  late AssetsDatabase db;
  late QuestionDao dao;

  setUp(() {
    db = AssetsDatabase(NativeDatabase.memory());
    dao = QuestionDao(db);
    // 插入测试数据
    await db.into(db.questions).insert(...);
  });

  tearDown(() => db.close());

  test('getById returns correct question', () async {
    final result = await dao.getById(1);
    expect(result, isNotNull);
    expect(result!.year, equals(2024));
  });

  test('getFilterOptions returns distinct values', () async { ... });
  test('search with filters returns filtered list', () async { ... });
  test('countByType returns correct count', () async { ... });
}
```

**每个 DAO 的测试重点：**

| DAO | 最少测试数 | 关键场景 |
|-----|-----------|---------|
| question_dao | 6 | getById(存在/不存在)、search(全量/各筛选组合)、getFilterOptions、countByType |
| assignment_dao | 3 | listAll(空/有数据)、getById、getQuestions |
| lecture_dao | 4 | getAllCourses、getChapters(存在/空)、getContent |
| progress_dao | 8 | CRUD 各操作、getAttempts(多个存档排序)、createAttempt(递增)、updateStatus |
| rating_dao | 3 | getRating(存在/不存在)、upsert(新建/覆盖) |
| preference_dao | 5 | CRUD 完整流程、count |
| sync_queue_dao | 8 | enqueue、getPending(分页/排序)、markSuccess/markFailed、clearAll、cleanup 清理规则 |
| achievement_dao | 5 | getUnlockedCount、upsertProgress、getLoginStreak、getSubmissionCount |
| statistics_dao | 5 | getDailyRecords、getPointsByDay、getTypeDistribution、getTotalQuestions |
| exam_dao | 7 | 创建/查询/删除 paper、toggleLike/Collect、getPreview、getQuickAnswers |
| user_dao | 5 | getProfile(存在/不存在)、saveProfile、getPointsHistory、getStreakDays |

**合计：~59 个测试用例**

### 2.1.4 — 操作清单

1. 在 `flutter_app/lib/data/database/` 下创建 `assets_database.dart`
2. 在 `flutter_app/lib/data/database/` 下创建 `lectures_database.dart`
3. 在 `flutter_app/lib/data/database/` 下创建 `app_database.dart`
4. 运行 `dart run drift_dev build` 确认代码生成通过
5. 验证 `build.yaml` 中 drift_dev 配置正确
6. 在 `flutter_app/lib/data/daos/` 下逐个创建 11 个 DAO 文件
7. 对每个 DAO 编写 memory DB 测试
8. 运行 `flutter test` 确认全部测试通过

---

## 2.2 — DatabaseProvider + ApiClient（0.5 天）

### 涉及文件

```
flutter_app/lib/data/database/database_provider.dart
flutter_app/lib/data/api/
├── api_client.dart          # Dio 单例 + 3 拦截器
├── auth_api.dart            # login/register/refresh/logout
├── sync_api.dart            # push/version check
└── user_api.dart            # me/update/avatar
```

### 2.2.1 — DatabaseProvider

**位置：** `lib/data/database/database_provider.dart`

```dart
/// 三库生命周期管理。
/// 唯一单例——数据库连接是重量级资源，必须全局共用一个。
class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._();
  factory DatabaseProvider() => _instance;

  AppDatabase? _appDb;
  AssetsDatabase? _assetsDb;
  LecturesDatabase? _lecturesDb;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _assetsDb = AssetsDatabase(LazyDatabase(() async {
      // 从应用文档目录 assets.db 文件打开
      return NativeDatabase(File('${dir.path}/assets.db'));
    }));
    _lecturesDb = LecturesDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/lectures.db'));
    }));
    _appDb = AppDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/user.db'));
    }));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

  AppDatabase get appDb => _appDb!;
  AssetsDatabase get assetsDb => _assetsDb!;
  LecturesDatabase get lecturesDb => _lecturesDb!;

  /// 替换 assets.db（更新时调用）
  Future<void> replaceAssetsDb(String newPath) async {
    await _assetsDb?.close();
    // 备份并替换文件
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/assets.db');
    await File(newPath).copy(target.path);
    _assetsDb = AssetsDatabase(NativeDatabase(target));
  }

  Future<void> replaceLecturesDb(String newPath) async { ... }

  /// 清空 user.db（登出时调用）
  Future<void> clearUserDb() async {
    await _appDb?.close();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/user.db');
    if (await file.exists()) await file.delete();
    _appDb = AppDatabase(NativeDatabase(file));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }
}
```

#### 首次启动 assets.db 放入

首次启动时如果 assets.db 不存在，需从 Flutter bundle 复制：

```dart
Future<void> _ensureDefaultAssets() async {
  final dir = await getApplicationDocumentsDirectory();
  final assetsFile = File('${dir.path}/assets.db');
  if (!await assetsFile.exists()) {
    final data = await rootBundle.load('assets/db/assets.db');
    await assetsFile.writeAsBytes(data.buffer.asUint8List());
  }
  // 同上 lectures.db
}
```

**在 `init()` 开头调用 `_ensureDefaultAssets()`。**

### 2.2.2 — ApiClient + 三个拦截器

**位置：** `lib/data/api/api_client.dart`

```dart
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;

  void init({String baseUrl = 'https://zhangyuzhixue.top/api/v1/'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.addAll([
      _AuthInterceptor(),      // 请求前 + Authorization header
      _RefreshInterceptor(),   // 401 → 刷新 → 重试
      _ErrorInterceptor(),     // 统一解析 {code, message, data}
    ]);
  }

  Dio get dio => _dio;

  @visibleForTesting
  void setMockAdapter(MockAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }
}
```

#### _AuthInterceptor

```dart
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AppPrefs().accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ' + token;
    }
    handler.next(options);
  }
}
```

#### _RefreshInterceptor（带同步锁）

```dart
class _RefreshInterceptor extends Interceptor {
  bool _isRefreshing = false;
  final _pendingRequests = <({RequestOptions options, ErrorInterceptorHandler handler})>[];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      // 已有刷新请求在飞行，排队等待
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = AppPrefs().refreshToken;
      if (refreshToken == null) {
        _redirectToLogin();
        return handler.resolve(err.response!);
      }

      final response = await Dio().post(
        '${err.requestOptions.baseUrl}/auth/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'] as String;
      await AppPrefs().saveAccessToken(newAccess);

      // 重试原请求
      err.requestOptions.headers['Authorization'] = 'Bearer ' + newAccess;
      final retryResponse = await _dio.fetch(err.requestOptions);
      handler.resolve(retryResponse);

      // 处理排队请求
      _processPending(newAccess);
    } catch (e) {
      AppPrefs().clearAll();
      _redirectToLogin();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  void _processPending(String newToken) { ... }
  void _redirectToLogin() { ... }
}
```

#### _ErrorInterceptor

```dart
class _ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 统一解析 {code, message, data}
    final body = response.data;
    if (body is Map && body['code'] != null && body['code'] != 0) {
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: ApiException(
          code: body['code'] as int,
          message: body['message'] as String? ?? '未知错误',
          httpStatus: response.statusCode,
        ),
      ));
    } else {
      handler.next(response);
    }
  }
}
```

### 2.2.3 — API 类

#### auth_api.dart

```dart
class AuthApi {
  final ApiClient _client;
  const AuthApi(this._client);

  Future<LoginResult> login(LoginRequest req) async { ... }
  Future<void> register(RegisterRequest req) async { ... }
  Future<RefreshResult> refresh(String refreshToken) async { ... }
}
```

#### sync_api.dart

```dart
class SyncApi {
  final ApiClient _client;
  const SyncApi(this._client);

  Future<VersionStatus> checkVersion(String type) async { ... }
  Future<PushBatchResult> pushBatch(List<Map<String, dynamic>> items) async { ... }
}
```

#### user_api.dart

```dart
class UserApi {
  final ApiClient _client;
  const UserApi(this._client);

  Future<UserInfo> getInfo() async { ... }
  Future<void> updateProfile(Map<String, dynamic> data) async { ... }
  Future<String> uploadAvatar(String localPath) async { ... }
}
```

### 2.2.4 — 测试计划

| 测试 | 场景 | 数量 |
|------|------|------|
| DatabaseProvider | init() 成功打开三库、replaceAssetsDb 后数据可读、clearUserDb 后为空 | 4 |
| ApiClient | init() 后 dio 配置正确、setMockAdapter 生效 | 2 |
| AuthInterceptor | 有 token 时加 header、无 token 不加 | 2 |
| RefreshInterceptor | 401 触发刷新成功、401 触发刷新失败（跳登录）、并发 401 排队 | 4 |
| ErrorInterceptor | code=0 正常通过、code≠0 转为 ApiException | 2 |
| AuthApi | login/register/refresh 各一个 mock 测试 | 3 |
| SyncApi | checkVersion/pushBatch 各一个 mock 测试 | 2 |

**合计：~19 个测试用例**

### 2.2.5 — 操作清单

1. 创建 `database_provider.dart`，实现三库生命周期
2. 创建 `api_client.dart`，实现 Dio 单例 + 三个拦截器
3. 创建 `auth_api.dart` / `sync_api.dart` / `user_api.dart`
4. 编写拦截器链测试（重点：RefreshInterceptor 的同步锁 + 排队）
5. 编写 API mock 测试
6. `flutter test` 全部通过

---

## 2.3 — AppPrefs + ConnectivityMonitor（0.5 天）

### 涉及文件

```
flutter_app/lib/data/prefs/app_prefs.dart
flutter_app/lib/data/network/connectivity_monitor.dart
```

### 2.3.1 — AppPrefs

**位置：** `lib/data/prefs/app_prefs.dart`

仅封装全局 key（`app_` 前缀），页面级 key 前缀规范在 Flutter 代码规范 §1.5 和 §2.2 中定义。

```dart
class AppPrefs {
  static final AppPrefs _instance = AppPrefs._();
  factory AppPrefs() => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token
  String? get accessToken => _prefs!.getString(Keys.accessToken);
  String? get refreshToken => _prefs!.getString(Keys.refreshToken);
  Future<bool> saveAccessToken(String token) =>
      _prefs!.setString(Keys.accessToken, token);
  Future<bool> saveRefreshToken(String token) =>
      _prefs!.setString(Keys.refreshToken, token);

  // User cache
  Map<String, dynamic>? get userCache { ... }
  Future<bool> saveUserCache(Map<String, dynamic> data) { ... }

  // DB versions
  int get qbankVersion => _prefs!.getInt(Keys.qbankVersion) ?? 0;
  int get lectureVersion => _prefs!.getInt(Keys.lectureVersion) ?? 0;
  Future<bool> saveQbankVersion(int v) => _prefs!.setInt(Keys.qbankVersion, v);
  Future<bool> saveLectureVersion(int v) => _prefs!.setInt(Keys.lectureVersion, v);

  // Course access cache
  List<int> get accessibleCourseIds { ... }
  Future<bool> saveAccessibleCourseIds(List<int> ids) { ... }

  // Update flow cooldown (避免每次启动都弹更新横幅)
  int? get lastUpdatePromptTimestamp { ... }
  Future<bool> saveLastUpdatePromptTimestamp(int ts) { ... }

  // Rating cooldown (同页面冷却)
  bool isRatingCooldownActive(String pageUrl) { ... }
  Future<void> setRatingCooldown(String pageUrl) { ... }

  Future<bool> clearAll() => _prefs!.clear();
}

class Keys {
  static const accessToken = 'app_auth_token';
  static const refreshToken = 'app_refresh_token';
  static const userCache = 'app_user_cache';
  static const qbankVersion = 'app_qbank_version';
  static const lectureVersion = 'app_lecture_version';
  static const accessibleCourses = 'app_accessible_courses';
  static const lastUpdatePrompt = 'app_last_update_prompt';
  static const ratingCooldownPrefix = 'app_rating_cooldown_';
  static const firstLaunchComplete = 'app_first_launch';
}
```

### 2.3.2 — ConnectivityMonitor

**位置：** `lib/data/network/connectivity_monitor.dart`

```dart
class ConnectivityMonitor {
  static final ConnectivityMonitor _instance = ConnectivityMonitor._();
  factory ConnectivityMonitor() => _instance;

  final _connectivity = Connectivity();
  final _stateController = BehaviorSubject<bool>.seeded(true);

  bool get isOnline => _stateController.value;
  Stream<bool> get onConnectivityChanged => _stateController.stream;

  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _stateController.add(online);
    });
  }

  void dispose() => _stateController.close();
}
```

### 2.3.3 — 测试计划

| 测试 | 数量 |
|------|------|
| AppPrefs: token 读写 | 2 |
| AppPrefs: version 读写 | 2 |
| AppPrefs: clearAll 清空 | 1 |
| AppPrefs: userCache | 2 |
| ConnectivityMonitor: init 后状态 | 1 |

**合计：~8 个测试用例**

### 2.3.4 — 操作清单

1. 创建 `app_prefs.dart`，实现所有全局 key 的读写
2. 创建 `connectivity_monitor.dart`
3. 编写 AppPrefs 和 ConnectivityMonitor 测试
4. `flutter test` 全部通过

---

## 2.4 — 13 个 Repository 全部实现（1.5 天）

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

### 2.4.1 — 实现方式

将 `docs/05-Flutter/Repository/*.dart` 设计稿复制到 `lib/domain/`，并替换 `throw UnimplementedError` 为真实实现。

**三个变更要点：**
1. 设计稿中大部分方法是 `static`——**改为实例方法**（构造注入 DAO）
2. 去掉 `fromJson`（Repository 从本地 DB 读数据，不从 API 反序列化）
3. 补充 import 和依赖注入

### 2.4.2 — 依赖注入清单

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

### 2.4.3 — Repository 构造方式

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
  final UserApi _userApi;  // 用于同步组卷到服务器

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

### 2.4.4 — 5 个尾部算法类的实现要求

| 算法类 | 所属 Repository | 实现细节文档 | 核心代码行数估算 |
|--------|----------------|-------------|-----------------|
| `_PointsCalculator` | UserRepository | `user_repository.dart` 尾部注释 | ~50 行 |
| `_ExamFilterEngine` | ExamRepository | `exam_repository.dart` 尾部注释 | ~40 行 |
| `_ExamGenerator` | ExamRepository | `exam_repository.dart` 尾部注释（含 300+ 行算法描述） | ~120 行 |
| `_RecommendationEngine` | RecommendRepository | `recommend_repository.dart` 尾部注释 | ~100 行 |
| `_StatisticsAggregator` | StatisticsRepository | `statistics_repository.dart` 尾部注释 | ~80 行 |

**合计算法代码：~390 行**

### 2.4.5 — 测试计划

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

**尾部算法类单独测**（5 个私有类的算法逻辑作为 Repository 的组成部分覆盖）：

| 私有类 | 关键场景 | 测试数 |
|--------|---------|-------|
| `_ExamFilterEngine.compute` | 空池、正常统计、无对应题型 | 3 |
| `_ExamGenerator.confirm` | 正常组卷（贪心+交换3轮）、池子不足、allowShortfall | 5 |
| `_RecommendationEngine` | 冷启动（<5 条记录）、路线A（概念掌握度）、路线B（卡片卡住率）、边界（排除已做/刚错） | 6 |
| `_StatisticsAggregator` | 7 天记录、30 天降采样、无数据 | 3 |
| `_PointsCalculator` | earned/bonus/spent/available 四种汇总、无数据 | 3 |

**合计：~20 个测试用例**

### 2.4.6 — 操作清单

1. 在 `lib/domain/` 下创建 13 个 Repository 文件
2. 每个文件：复制设计稿 + 替换 UnimplementedError + 改 static 为实例方法 + 构造注入
3. 对 5 个尾部算法类逐一实现算法逻辑
4. 编写 Repository 集成测试（memory DB）
5. 编写尾部算法类单元测试
6. `flutter test` 全部通过

---

## 2.5 — 同步引擎 + 更新机制（1 天）

### 涉及文件

```
flutter_app/lib/data/sync/
├── sync_types.dart            # 枚举 + 数据模型（从设计稿复制，替换为 Drift DataClass）
├── sync_queue_dao.dart        # 队列 DAO（已在 2.1 中创建，本步骤对接）
├── sync_pusher.dart           # 推送核心
└── sync_manager.dart          # 总入口

flutter_app/lib/data/sync/update_manager.dart  # 版本检查 + .db 下载 + 替换
```

### 2.5.1 — SyncPusher（对接 DAO + Api）

从 `docs/05-Flutter/sync/sync_pusher.dart` 设计稿复制，替换抽象接口为真实实现：

```dart
class SyncPusher {
  static const int maxRetries = 5;
  static const int batchSize = 20;

  final SyncQueueDao _dao;
  final SyncApi _api;

  SyncPusher(this._dao, this._api);

  /// 推送所有待同步数据
  Future<PushBatchResult> pushAll() async {
    // 1. 取一批 (pending + inProgress 的"孤儿记录")
    // 2. 标记 inProgress
    // 3. 调用 _api.pushBatch()
    // 4. 逐条处理结果（成功→markSuccess，失败→markFailed）
    // 5. cleanup()
    // 6. 重复直到队列空
    ...
  }
}
```

### 2.5.2 — SyncManager（总入口）

```dart
class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;

  SyncQueueDao? _queueDao;
  SyncPusher? _pusher;
  DateTime _lastPushTime = DateTime(2000);

  Future<void> init(SyncQueueDao queueDao, SyncApi api) async { ... }

  // 外部接口
  Future<void> enqueue({entityType, operation, localId, payload}) async { ... }
  Future<PushBatchResult> pushNow() async { ... }
  Future<void> onAppStart() async { ... }  // 推送积压 + 检查版本
  Future<void> clearQueue() async { ... }
}
```

### 2.5.3 — UpdateManager（版本检查 + .db 下载 + 替换）

```dart
class UpdateManager {
  final SyncApi _syncApi;
  final DatabaseProvider _dbProvider;

  UpdateManager(this._syncApi, this._dbProvider);

  /// 入口：并发检查 qbank 和 lecture 版本
  Future<UpdateSummary> checkAll() async { ... }

  /// 下载 .db.gz → 解压 → checksum 验证 → 替换
  Future<void> downloadAndReplace(
    String type,    // 'qbank' | 'lecture'
    String downloadUrl,
    String expectedChecksum,
    void Function(double progress)? onProgress,
  ) async { ... }

  /// 判断是否需要强制更新
  bool shouldForceUpdate({
    required int localVersion,
    required int serverVersion,
    required bool serverForceUpdate,
  }) {
    // 1. 服务端标注 force_update = true
    // 2. 本地落后 ≥ 3 个版本
    return serverForceUpdate || (serverVersion - localVersion >= 3);
  }

  /// 判断是否更新横幅
  bool shouldShowBanner({
    required int localVersion,
    required int serverVersion,
  }) {
    return serverVersion > localVersion;
  }
}
```

### 2.5.4 — 启动流程整合

在 App 初始化流程中：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPrefs().init();
  ApiClient().init(baseUrl: 'https://zhangyuzhixue.top/api/v1/');
  await DatabaseProvider().init();
  ConnectivityMonitor().init();

  final syncQueueDao = SyncQueueDao(DatabaseProvider().appDb);
  final syncApi = SyncApi(ApiClient());
  SyncManager().init(syncQueueDao, syncApi);

  // 启动后异步检查更新 + 推送积压
  SyncManager().onAppStart();  // 不 await（不阻塞主界面）

  runApp(const ZhangyuzhixueApp());
}
```

### 2.5.5 — 测试计划

| 测试 | 场景 | 数量 |
|------|------|------|
| SyncPusher.pushAll | 空队列、单批推送成功、分批推送、网络错误全部失败、部分成功部分失败 | 6 |
| SyncPusher.pushAll | 失败记录重试（retryCount < maxRetries 重新出队） | 2 |
| SyncPusher.pushAll | 永久失败处理（retryCount >= maxRetries 转为 permanentFailure） | 2 |
| SyncPusher.pushAll | 孤儿记录（inProgress 重新出队） | 1 |
| SyncPusher.pushAll | cleanup 规则（done 删除、permanentFailure 过期删除） | 2 |
| SyncManager | onAppStart 调用 push 和 version check | 2 |
| SyncManager | enqueue → pushNow → 队列为空 | 2 |
| SyncManager | 冷却检查（30 秒内重复调用跳过） | 2 |
| UpdateManager | checkAll 并发调两个 version 接口 | 2 |
| UpdateManager | shouldForceUpdate 判断逻辑 | 4 |
| UpdateManager | shouldShowBanner 判断逻辑 | 3 |

**合计：~28 个测试用例**

### 2.5.6 — 操作清单

1. 将设计稿 `sync_types.dart` 中的类型定义整合到 `lib/data/sync/sync_types.dart`
2. 实现 `sync_pusher.dart`（已依赖 2.1 中的 sync_queue_dao）
3. 实现 `sync_manager.dart`
4. 实现 `update_manager.dart`
5. 整合 `main.dart` 初始化流程
6. 编写同步引擎全部测试（28+ 场景）
7. 编写更新机制测试
8. `flutter test` 全部通过

---

## 三、依赖关系说明

```
2.1 Drift Databases + DAOs
  │
  ├─ 2.2 DatabaseProvider ─────────────────────┐
  │                                            │
  ├─ 2.2 ApiClient ────────────────────────────┤
  │                                            │
  ├─ 2.3 AppPrefs ────────────────────────────┼┤
  │                                            ││
  ├─ 2.3 ConnectivityMonitor ──────────────────┼┤
  │                                             │
  └─────────────────────────────────────────────┘
       ↓                                        ↓
  2.4 Repositories（依赖 DAO + Api）        2.5 Sync Engine（依赖 DAO + Api）
                                                │
                                            UpdateManager（依赖 SyncApi + DatabaseProvider）
```

| 步骤 | 依赖 | 可并行 |
|------|------|-------|
| 2.1 | 无 | — |
| 2.2 | 2.1（DatabaseProvider 需要 Database） | — |
| 2.3 | 无 | ✅ 与 2.1/2.2 并行 |
| 2.4 | 2.1 + 2.2 + 2.3 | — |
| 2.5 | 2.1 + 2.2 + 2.3 | ✅ 与 2.4 并行 |

---

## 四、测试汇总

| 层级 | 测试项 | 测试数 |
|------|-------|-------|
| L1: DAO 单元测试 | 11 个 DAO × memory DB | ~59 |
| L2: 基础设施 | DatabaseProvider + ApiClient 拦截器 + AppPrefs + Connectivity | ~19 |
| L3: 基础设施 | AppPrefs + ConnectivityMonitor | ~8 |
| L4: Repository 集成 | 13 个 Repository + 5 个尾部算法类 | ~75 |
| L5: 同步引擎 | SyncPusher + SyncManager + UpdateManager (30+ 场景) | ~28 |
| **合计** | | **~189 个测试** |

> 测试嵌入到每个子步骤中，做到哪步测到哪步，不攒到最后。

---

## 五、验收标准

1. `flutter test` 全部通过（~189 个测试）
2. 3 个 Drift Database 均能正确打开 assets.db / lectures.db / user.db
3. 11 个 DAO 对各自表完成 CRUD 覆盖
4. DatabaseProvider 能成功替换 assets.db 和 lectures.db
5. ApiClient 三个拦截器链在 mock 测试中完整通过
6. Token 刷新同步锁机制在并发 401 场景下正确排队
7. 13 个 Repository 从本地 DB 读取并安全组合数据
8. 5 个尾部算法类的算法逻辑测试通过
9. SyncPusher 能完成队列推送 + 重试 + cleanup 全流程
10. UpdateManager 能判断强制/非强制更新规则
11. App 启动流程不阻塞主界面
