# Phase 2.1 — 3 个 Drift Database + 11 个 DAO

> 本文档是 [Phase-2-Flutter数据层.md](./Phase-2-Flutter数据层.md) 中 2.1 子步骤的细化执行方案。
> 状态：**已完成** | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **2.1** 🔧CI | 3 个 Drift Database（assets/lectures/user）+ 11 个 DAO | 1.5 天 | ✅ |

### 前置条件

- [x] `docs/05-Flutter/` 下 Repository 设计稿（13 个文件）已就位
- [x] Flutter 脚手架已完成（Phase 0.3），drift/dio 等依赖已添加
- [x] `build.yaml` 中 drift_dev 已配置（sqlite3 使用系统库）

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) | 全部表定义（assets + user） |
| [`构建脚本设计.md`](../02-数据/构建脚本设计.md) | ASSETS_TABLES 与 LECTURE_TABLES 定义 |
| [`数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | DAO→Database 层间契约 |
| [`flutter_app/lib/data/database/`](../../flutter_app/lib/data/database/) | 三个 Drift Database 实现 |
| [`flutter_app/lib/data/daos/`](../../flutter_app/lib/data/daos/) | 11 个 DAO 实现 |

---

## 2.1 — 3 个 Drift Database + 11 个 DAO

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

### 实现要点

#### 2.1.1 — Drift Database 定义

**原则：**
- 表定义严格参照 `docs/02-数据/数据库结构设计.md` 和 `构建脚本设计.md` 中的 `ASSETS_TABLES`/`LECTURE_TABLES`
- 用户表（user.db）参考数据库结构设计 §5–§7
- 镜像原则：assets/lectures 库表结构与服务端 Django 一致，差异仅换行/格式/本地特有字段

**assets_database.dart（位置：** `lib/data/database/assets_database.dart`）

表清单：questions, choice_ext, sub_questions, solution_methods, solution_steps, concept_tags, knowledge_cards, question_concept_tags, question_knowledge_cards, achievement_defs, level_configs, _meta（共 12 个表）

> **注意：** 当前 assets.db 构建脚本中 `ASSETS_TABLES` 定义了 14 个表（含 course / assignment / assignment_question 三个课程相关表）。这三个表同时存在于 assets.db 和 lectures.db，但只通过 lectures.db 读取。assets_database.dart 中可省略 course/assignment/assignment_question 这三个冗余表，如果构建脚本生成的 assets.db 包含它们，就保留以保持兼容。

**lectures_database.dart（位置：** `lib/data/database/lectures_database.dart`）

表清单：courses, chapters, lecture_contents, assignments, assignment_questions, _meta（共 6 个表）

**app_database.dart（位置：** `lib/data/database/app_database.dart`）

表清单（共 15 个表，参照数据库结构设计 §5–§7 的 `[本地用户]` 和 `[镜像]` 标注）：
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
- sync_queue（§7.3，含 entity_type/entity_id/payload/status/retry_count 等）

**build.yaml 配置（验证即可）：**
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

#### 2.1.2 — 11 个 DAO

**DAO 通用规则：** 构造注入，基础 CRUD 由 Drift 自动生成，DAO 封装更语义化的查询。

```dart
class QuestionDao {
  final AssetsDatabase _db;
  const QuestionDao(this._db);

  Future<QuestionRow?> getById(int id) =>
      _db.select(_db.questions)..where((t) => t.id.equals(id)).getSingleOrNull();

  Future<List<QuestionRow>> search({...}) async { ... }
  Future<({List<int> years, List<String> regions, List<String> conceptTags})>
      getFilterOptions() async { ... }
  Future<int> countByType(String questionType, {...}) async { ... }
}
```

### 验证方式

**类型：** DAO 单元测试（in-memory Drift）

```dart
void main() {
  late AssetsDatabase db;
  late QuestionDao dao;

  setUp(() {
    db = AssetsDatabase(NativeDatabase.memory());
    dao = QuestionDao(db);
    // 插入测试数据
  });

  tearDown(() => db.close());

  test('getById returns correct question', () async { ... });
  test('getFilterOptions returns distinct values', () async { ... });
  // ...
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

### 操作清单

1. 在 `flutter_app/lib/data/database/` 下创建 `assets_database.dart`
2. 在 `flutter_app/lib/data/database/` 下创建 `lectures_database.dart`
3. 在 `flutter_app/lib/data/database/` 下创建 `app_database.dart`
4. 运行 `dart run drift_dev build` 确认代码生成通过
5. 验证 `build.yaml` 中 drift_dev 配置正确
6. 在 `flutter_app/lib/data/daos/` 下逐个创建 11 个 DAO 文件
7. 对每个 DAO 编写 memory DB 测试
8. 运行 `flutter test` 确认全部测试通过

### 注意事项

- `autoIncrement()` 用于 Drift 语法兼容，实际 ID 由服务端分配
- `assets.db` 和 `lectures.db` 中的 `course/assignment/assignment_question` 三表同时存在于两个库，客户端仅通过 lectures.db 读取，避免混淆
- memory DB 测试用后必须 `tearDown(() => db.close())` 防止资源泄漏
