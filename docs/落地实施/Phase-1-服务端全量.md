# Phase 1 — 服务端全量（7 天，每步测）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 1 的细化执行方案。
> 状态：**已完成** | 执行日期：2026-07-10 | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **1.1** | 5 App 的 models.py → makemigrations → migrate | 0.5 天 | ✅ |
| **1.2** | 🏛 题库数据迁移（旧版→新版，798 题） | 1 天 | ✅ |
| **1.3** 🔧CI | JWT 认证 API + 创建 dev 测试用户 + drf-spectacular 文档 | 0.5 天 | ✅ |
| **1.4** | 同步 API（version check ×2 + sync push）+ 教师端服务端改动 | 1 天 | ✅ |
| **1.5** | 用户/组卷/点赞/收藏/统计 API | 1.5 天 | ✅ |
| **1.6** | 构建脚本（build_assets.py + build_lectures.py） | 1 天 | ✅ |
| **1.7** | PDF 视图（request-token + pdf/view + 模板 + 字体） | 1 天 | ✅ |
| **1.8** | Admin system/tools 页面（构建按钮、生成邀请码、批量导入） | 0.5 天 | ✅ |
| | **合计** | **~7 天** | |

---

> **⚙️ SystemConfig 标记说明：** 冷却时长、重试次数、积分奖励值、组卷价格等业务参数已抽入 `SystemConfig` 表（详见 [数据库结构设计 §5.10](../02-数据/数据库结构设计.md#510-systemconfig--系统配置-服务器)），通过 `system/config_reader.py` 读取。实现时直接调用 `get_config_int()` / `get_config_float()`，不再在代码中硬编码。
> **🔧CI 标记说明：** 执行到该步骤时，需同步更新 CI 配置（详见 [00-落地计划.md §CI/CD](../00-落地计划.md#cicdphase-0-搭建贯穿全程)）。

### 前置条件

- [x] Phase 0 已完成：Django 5 App 骨架就绪、Flutter 骨架就绪、CI 全绿
- [x] 已读取 `docs/02-数据/数据库结构设计.md` 全部表定义
- [x] 已读取 `docs/03-服务端/API设计.md` 全部端点定义
- [x] 旧版 `D:\Hermes\math_platform\db.sqlite3` 可访问（798 题）

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) | 所有表定义（5 App × ~40 表） |
| [`API设计.md`](../03-服务端/API设计.md) | 全部端点规范（984 行） |
| [`服务端架构.md`](../03-服务端/服务端架构.md) | App 划分与部署 |
| [`构建脚本设计.md`](../02-数据/构建脚本设计.md) | 构建流程与 ASSETS_TABLES 定义 |
| [`PDF方案设计.md`](../03-服务端/PDF方案设计.md) | PDF 渲染流程

---

## 1.1 — 5 App models.py + migrate（0.5 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/accounts/models.py` | 新增 Student、Teacher、InvitationCode、UserLoginLog |
| `server/accounts/admin.py` | 注册 Student、Teacher、InvitationCode |
| `server/qbank/models.py` | 新增 BaseQuestion、ChoiceExt、SubQuestion、SolutionMethod、SolutionStep、ConceptTag、KnowledgeCard、QuestionConceptTag、QuestionKnowledgeCard |
| `server/qbank/admin.py` | 注册全部模型，inline 配置 |
| `server/courses/models.py` | 新增 Course、ClassGroup、ClassCourse、ClassCourseAssignment、Document、Assignment、AssignmentQuestion |
| `server/courses/admin.py` | 注册全部模型 |
| `server/interactions/models.py` | 新增 StudentSubmission、SubmissionDetail、StepFeedback、CardFeedback、QuestionRating、CustomPaper、CustomPaperQuestion、PaperLike |
| `server/interactions/admin.py` | 注册全部模型 |
| `server/system/models.py` | 新增 DbVersion、AppVersion、Announcement、PointsTransaction、StudentAchievement、LevelConfig、AchievementDef |
| `server/system/admin.py` | 注册全部模型，ToolsAdminView |

### 实现要点

**accounts/models.py：**
- `Student`：OneToOneField → User，ForeignKey → ClassGroup（nullable）
- `Teacher`：OneToOneField → User，与 Student 互斥
- `InvitationCode`：code（char unique）、is_used、used_by（FK→User nullable）、expires_at、created_at
- `UserLoginLog`：FK→Student，login_date（unique）、created_at

**qbank/models.py：**
- `BaseQuestion`：见数据库结构设计.md 3.1 节
  - `images` = JSONField(blank=True, default=list)
  - `question_type` = CharField(choices=('choice','fill','solution'))
  - `difficulty` / `calculation` = FloatField（0-10，设计文档注释 1-5 是错的，实际 0-10）
  - `concept_tags` = ManyToManyField(ConceptTag, through=QuestionConceptTag)
  - `knowledge_cards` = ManyToManyField(KnowledgeCard, through=QuestionKnowledgeCard)
  - **注意：** 不叫 `Question` 而叫 `BaseQuestion`（DRF 的 `ModelViewSet` 不自动加 `s` 后缀，但命名上避免与 SQL 保留字冲突）
- `ChoiceExt`：OneToOneField → BaseQuestion
- `SubQuestion`：FK→BaseQuestion，自关联 parent，新增 answer 字段
- `SolutionMethod`：FK→SubQuestion
- `SolutionStep`：FK→SolutionMethod，card_titles = JSONField
- `ConceptTag`：自关联 parent
- `KnowledgeCard`：title + content
- `QuestionConceptTag` / `QuestionKnowledgeCard`：显式中间表（构建脚本需要直接 QuerySet 操作）

**courses/models.py：**
- `Course`：name + description
- `ClassGroup`：name（避开 Python `Class` 保留字）
- `ClassCourse`：FK→ClassGroup + FK→Course + start_date + end_date
- `ClassCourseAssignment`：FK→ClassCourse + FK→Assignment + publish_at + deadline + is_active
- `Document`：course_id（FK）+ chapter（VARCHAR）+ title + md_content + updated_at
  - **注意：** Document 的 md_content 中包含分隔符（`<!-- pagebreak -->` / `<!-- reveal -->`）
- `Assignment`：title + description + course_id（FK） + questions（M2M via AssignmentQuestion）
- `AssignmentQuestion`：FK→Assignment + FK→BaseQuestion + sort_order

**interactions/models.py：**
- `StudentSubmission`：FK→Student + FK→Assignment(nullable) + created_at + updated_at
- `SubmissionDetail`：FK→StudentSubmission + FK→BaseQuestion + attempt_number + answer_text + is_correct(nullable) + status(choices)
- `StepFeedback`：FK→SubmissionDetail + FK→BaseQuestion + sub_question_index + method_id(nullable) + step_number + status(choices: full_correct/partial_correct/wrong)
- `CardFeedback`：FK→SubmissionDetail + FK→BaseQuestion + card_title + card_status(choices: mastered/understood/not_understood)
- `QuestionRating`：FK→Student + FK→BaseQuestion + difficulty_score + calculation_score + elegance_score + created_at，UNIQUE(student, question)
- `CustomPaper`：FK→Student + title + description + filter_snapshot(JSON) + is_public + view_count + created_at + updated_at
- `CustomPaperQuestion`：FK→CustomPaper + FK→BaseQuestion + sort_order
- `PaperLike`：FK→Student + FK→CustomPaper + created_at，UNIQUE(student, paper)

**system/models.py：**
- `DbVersion`：db_type(choices: qbank/lecture，unique) + schema_version + data_version + checksum + size_bytes + download_url + force_update + message + built_at
- `AppVersion`：platform(choices: android/ios) + version_name + version_code + force_update + download_url + release_notes + created_at
- `Announcement`：title + content + is_active + created_at
- `PointsTransaction`：FK→Student + amount + transaction_type(earn/spend) + source(CharField choices) + source_object_id(nullable) + description + created_at
- `StudentAchievement`：FK→Student + achievement_code + progress + is_unlocked + unlocked_at(nullable) + updated_at
- `LevelConfig`：level(PK) + min_xp + title + icon_emoji(nullable)
- `AchievementDef`：code(unique) + name + description + icon(nullable) + icon_emoji(nullable) + category + category_label(nullable) + display_order + trigger_type + threshold

### SQLite 注意事项

SQLite 不支持 `ALTER TABLE ... RENAME COLUMN`。Django 迁移遇到字段改名会生成 `RemoveField` + `AddField`，导致数据丢失。

**因此 models.py 必须一次写准，后续只 AddField 不 RenameField。**

如果开发中途需要改字段名（无数据时），可手动回滚迁移：
```bash
python manage.py migrate qbank zero
# 修改 models.py
python manage.py makemigrations qbank
python manage.py migrate qbank
```

### 验证方式

```bash
python manage.py makemigrations      # 确认生成迁移文件
python manage.py migrate             # 确认 34+Django + N 自定义迁移通过
python manage.py check               # 零问题
python manage.py createsuperuser     # 创建管理员账号
```

---

## 1.2 — 题库数据迁移（1 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/scripts/__init__.py` | 新建（空包） |
| `server/scripts/migrate_questions.py` | **新建**：迁移主脚本 |

### 前置条件

- 旧版 `D:\Hermes\math_platform\db.sqlite3` 可访问
- `questions_question` 表含 **798 题**（3 条 year=2099 测试数据已排除）
- 1.1 迁移完成，新版表结构就绪

### 实现要点

`migrate_questions.py` 以独立脚本运行（`python scripts/migrate_questions.py`），直接连接新旧两个 SQLite 数据库，不走 Django ORM 连接（避免环境依赖问题）。

**执行流程：**

```
1. 连接旧版 db.sqlite3（sqlite3 模块直接读）
2. 连接新版 db.sqlite3（Django DB）
3. 迁移概念标签树（ConceptTag）
   └── 旧版 questions_concepttag → 新版 concept_tag
       ├── 保留 id（迁移脚本中留旧→新 id 映射）
       └── parent_id 自关联（先插入全部，再更新 parent）
4. 迁移知识卡片（KnowledgeCard）
   └── 旧版 questions_knowledgecard → 新版 knowledge_card
5. 迁移题目主表（BaseQuestion）
   └── 主循环旧版 questions_question（按 id 升序）
       ├── year / exam / district / number → 新版对应字段（注意字段名映射）
       ├── question_type: 选择题/填空题/解答题 → choice/fill/solution
       ├── difficulty / workload: 旧版就是 0-10，直接复制（注释写的 1-5 是错的）
       ├── 从 question_text 提取 <img> 标签 → images JSON
       │   └── 正则 r'<img[^>]+src="([^"]+)"[^>]*>' → 提取 src
       ├── stem = 清除 <img> 标签后的纯 markdown
       └── default_score = 默认 0（旧版无此字段）
6. 建立 ChoiceExt（选择题选项）
   └── 旧版 questions_choiceext → 新版 choice_ext
7. 构建 SubQuestion → SolutionMethod → SolutionStep（三层嵌套）
   └── 从旧版 questions_questionstep 读取
       ├── subquestion=0 为第一小题（选填题只有一行）
       ├── group by (question_id, subquestion, method) → 逐层创建
       └── 保留 sort_order
8. 建立题目-概念标签 M2M
   └── 旧版 questions_question_concept_tag → 新版 question_concept_tag
9. 建立题目-知识卡片 M2M
   └── 从旧版 card_refs 反向解析（旧版字段名需确认）
10. 复制配图
    └── 旧版 "D:\Hermes\math_platform\data\附图\" → server/static/questions/images/
    ├── 改名为 question_{id}_{filename} 避免重名
    └── 格式保持 WebP
11. 验证
    ├── 题数 798 = 新版 question 表行数
    ├── 随机抽 5 题逐字段对比（旧版 ↔ 新版）
    └── 配图数量记录
```

### 注意事项

- **旧版字段名确认：** 迁移前需实际检查旧版 `PRAGMA table_info(questions_question)` 确认字段名与文档一致
- **事务：** 每步操作在独立事务中，失败可回退单步
- **幂等：** 脚本开头检查新版 question 表中是否有数据，有则跳过已迁移部分（或清空重建）
- **配图路径：** 旧版图片可能是 PNG/JPG，迁移时统一转为 WebP，放入 `static/questions/images/`

### 验证方式

```bash
python scripts/migrate_questions.py
# 期望输出：
# ✅ ConceptTag: 45 条
# ✅ KnowledgeCard: 367 条
# ✅ BaseQuestion: 798 条
# ✅ ChoiceExt: ~400 条
# ✅ SubQuestion: 798+ 条
# ✅ SolutionMethod: ~900 条
# ✅ SolutionStep: ~2500 条
# ✅ 配图: 312 张 → static/questions/images/
# ✅ 随机抽检 5 题：全部匹配
```

---

## 1.3 — JWT 认证 API（0.5 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/accounts/serializers.py` | **新建**：LoginSerializer、RegisterSerializer、UserSerializer、UserUpdateSerializer |
| `server/accounts/views.py` | 新增 LoginView、RegisterView、LogoutView |
| `server/accounts/urls.py` | 配置 login/register/refresh/logout 路由 |
| `server/accounts/permissions.py` | **新建**：IsStudent、IsTeacher 权限类 |
| `server/accounts/tests/test_auth.py` | **新建**：认证 API 测试 |

### 端点详细设计

**POST /api/v1/auth/login/**

请求体：
```json
{
  "username": "zhangsan",
  "password": "***",
  "app_type": "student"
}
```

响应：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "access": "eyJhbG...",
    "refresh": "eyJhbG...",
    "user": {
      "id": 1,
      "username": "zhangsan",
      "real_name": "张三",
      "role": "student",
      "student_id": "20261058417",
      "class_group_id": 2,
      "school": "北京四中",
      "gaokao_year": 2026,
      "avatar": null
    }
  }
}
```

**实现细节：**
- `app_type` 不做角色校验，仅用于区分来源
- `role` 由服务端查 Student/Teacher 表确定
- 管理员（`is_staff=True`）拒绝登录
- 登录成功返回 JWT（access 24h / refresh 30d）+ user 信息
- 登录失败（用户名/密码错误）返回 `code=40001`

**POST /api/v1/auth/register/**

请求体：
```json
{
  "invitation_code": "GR7X-K2P9-M4VB",
  "username": "zhangsan",
  "password": "***",
  "real_name": "张三",
  "phone": "13800138000",
  "gaokao_year": 2026
}
```

响应：
```json
{"code": 0, "message": "注册成功，请登录", "data": null}
```

**实现细节：**
- 校验邀请码（有效/未使用/未过期）
- 创建 User + Student（`class_group=null`）
- 标记邀请码为已使用
- **不返回 token**，跳转登录页

**POST /api/v1/auth/refresh/**

复用 `rest_framework_simplejwt.views.TokenRefreshView`，直接挂载即可。

**POST /api/v1/auth/logout/**

JWT 无状态，服务端仅返回成功。客户端清除本地 token。

### 权限类

```python
# accounts/permissions.py
class IsStudent(permissions.BasePermission):
    def has_permission(self, request, view):
        return hasattr(request.user, 'student')

class IsTeacher(permissions.BasePermission):
    def has_permission(self, request, view):
        return hasattr(request.user, 'teacher')
```

### Dev 测试用户

创建 `scripts/create_dev_users.py`：

| 用户 | 用户名 | 密码 | 角色 |
|------|--------|------|------|
| 管理员 | admin | admin123 | staff |
| 教师 | teacher1 | test123 | teacher |
| 学生1 | student1 | test123 | student |
| 学生2 | student2 | test123 | student |
| 学生3 | student3 | test123 | student |

创建测试邀请码若干（有效不过期）。

### 验证方式

```python
# pytest 4 场景
1. 注册（含邀请码校验失败）
2. 登录（含用户名密码错误）
3. Token 刷新（含 refresh 过期）
4. 登出
```

### CI 更新

> **⏰ 到这一步了：** 第一次写 pytest 测试，CI 的 Django job 需要加上 `pytest` 命令。
> 修改 `.github/workflows/ci.yml`，在 Django job 中新增一步：
> ```yaml
>       - name: pytest
>         working-directory: server
>         run: pip install pytest pytest-django -q && pytest
> ```
> 改一次后，后续 1.4~1.8 和 Phase 5 L6 的所有服务端测试自动进 CI，无需再改。

### API 文档

Phase 0 已配置 `drf-spectacular`。1.3 完成后访问：
- `/api/docs/` — OpenAPI JSON Schema
- `/api/docs/swagger/` — Swagger UI

---

## 1.4 — 同步 API（1 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/system/views.py` | 新增 VersionCheckView |
| `server/system/urls.py` | 新增 sync/ 路由 |
| `server/system/tests/test_version.py` | **新建**：版本检查测试 |
| `server/interactions/views.py` | 新增 SyncPushView |
| `server/interactions/serializers.py` | **新建**：SyncPushSerializer、batch 校验 |
| `server/interactions/urls.py` | 新增 sync/push/ 路由 |
| `server/interactions/tests/test_sync.py` | **新建**：同步推送测试 |

### 路由组织

所有 sync/ 端点统一在 `system/urls.py` 中定义：

```
/api/v1/sync/qbank/version/     → system.views.VersionCheckView (db_type=qbank)
/api/v1/sync/lecture/version/   → system.views.VersionCheckView (db_type=lecture)
/api/v1/sync/push/              → interactions.views.SyncPushView
```

实现时靠 URL kwarg 区分 qbank/lecture，视图函数复用。

### VersionCheckView

```python
class VersionCheckView(APIView):
    permission_classes = []  # 无需认证

    def get(self, request, db_type):
        version = DbVersion.objects.get(db_type=db_type)
        return Response({
            'code': 0,
            'data': {
                'schema_version': version.schema_version,
                'data_version': version.data_version,
                'force_update': version.force_update,
                'message': version.message,
                'download_url': version.download_url,
                'checksum': version.checksum,
                'size_bytes': version.size_bytes,
            }
        })
```

### SyncPushView

接收 batch 数组，按 entity_type 分发处理。

**支持的 entity_type：**

| entity_type | 处理逻辑 |
|-------------|---------|
| submission | 创建 StudentSubmission + SubmissionDetail |
| step_feedback | 创建 StepFeedback |
| card_feedback | 创建 CardFeedback |
| question_rating | 创建/更新 QuestionRating（UNIQUE student+question） |
| custom_paper | 创建 CustomPaper + CustomPaperQuestion |
| paper_like | 创建 PaperLike（UNIQUE student+paper） |

**关键实现要点：**
- `student_id` 从 JWT token 解析，**忽略请求体中的 student_id**（防篡改）
- 同一 batch 在同一事务中完成（`transaction.atomic()`）
- 按 batch 数组**顺序处理**（先 submission 后 detail/feedback）
- 返回 `server_ids` 映射（local_id → server_id），客户端回填

### 教师端服务端改动

已在 Phase 0 登录实现中完成（`app_type` 不做角色校验）。sync/push 的 entity 分发逻辑统一在 SyncPushView 中处理，组卷走 `request.user`，提交数据走 submission 中的 student_id（从 token 解析），无需额外改动。

### 验证方式

```python
# pytest 场景
1. GET /api/v1/sync/qbank/version/ → 正确格式
2. GET /api/v1/sync/lecture/version/ → 正确格式
3. POST /api/v1/sync/push/ (未认证) → 401
4. POST /api/v1/sync/push/ (batch 含 1 submission) → 200 + server_ids
5. POST /api/v1/sync/push/ (batch 含 submission + 2 step_feedback) → 全部提交
6. POST /api/v1/sync/push/ (无效 payload) → 40301
```

---

## 1.5 — 用户/组卷/点赞/收藏/统计 API（1.5 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/accounts/views.py` | 新增 UserMeView(GET/PATCH)、AvatarUploadView、LevelPercentileView |
| `server/accounts/urls.py` | 新增 user/ 路由 |
| `server/accounts/serializers.py` | 新增 UserUpdateSerializer |
| `server/accounts/tests/test_user.py` | **新建**：用户 API 测试 |
| `server/courses/views.py` | 新增 LectureCourseListView、ChapterListView、ChapterContentView |
| `server/courses/urls.py` | 新增 lectures/ 路由 |
| `server/courses/tests/test_lecture.py` | **新建**：讲义 API 测试 |

### 端点清单

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/api/v1/user/me/` | 当前用户信息 + points_summary |
| PATCH | `/api/v1/user/me/` | 更新 real_name/phone/gaokao_year |
| POST | `/api/v1/user/avatar/` | 头像上传（multipart） |
| GET | `/api/v1/user/level-percentile/` | 等级百分位 |
| GET | `/api/v1/lectures/courses/` | 课程列表 |
| GET | `/api/v1/lectures/courses/{id}/chapters/` | 章节目录 |
| GET | `/api/v1/lectures/chapters/{id}/content/` | 讲义内容 |

### UserMeView

- GET：查询 User → Student/Teacher → 计算 points_summary → 返回
- PATCH：只允许修改 real_name、phone、gaokao_year、school
- 不允许修改：username、role、points_summary

### AvatarUploadView

- 使用 Pillow（需加到 requirements.txt）
- resize 200×200
- 转码 WebP
- 文件路径：`media/avatars/{user_id}_{timestamp}.webp`
- 限制最大 2MB
- 不走 sync_queue

### LevelPercentileView

- 查询所有 Student 的累计积分（PointsTransaction GROUP BY student_id）
- 计算百分位：当前用户积分超过多少百分比的学生
- 可分页缓存（非强实时要求）

### Course/Chapter/Lecture APIs

- 教师可见全部课程，学生只可见自己班级关联的课程
- 讲义内容返回 Document.md_content 原样

### 验证方式

```python
# pytest 场景
1. GET /api/v1/user/me/ → 正确用户信息
2. PATCH /api/v1/user/me/ → 修改成功
3. POST /api/v1/user/avatar/ → 上传成功
4. POST /api/v1/user/avatar/ (>2MB) → 拒绝
5. GET /api/v1/lectures/courses/ → 课程列表
6. GET /api/v1/lectures/chapters/1/content/ → md_content 原样返回
```

---

## 1.6 — 构建脚本（1 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/scripts/__init__.py` | 已有（1.2 中创建） |
| `server/scripts/build_schemas.py` | **新建**：ASSETS_TABLES + LECTURE_TABLES 定义 |
| `server/scripts/build_assets.py` | **新建**：assets.db.gz 构建脚本 |
| `server/scripts/build_lectures.py` | **新建**：lectures.db.gz 构建脚本 |
| `server/scripts/build_utils.py` | **新建**：共享工具（_meta 表写入、checksum、gzip） |

### build_schemas.py

定义客户端 assets.db 和 lectures.db 的完整表结构。见 `构建脚本设计.md` 2.2 节的完整定义（约 250 行 Python dict），直接复制。

三种转换类型：
- `'direct'` — 字段名一致，直接 QuerySet.values() 复制
- `'m2m:Model.field'` — 从多对多关系生成中间表
- `'relation'` — 需复杂关联推导（SolutionStep.card_titles → KnowledgeCard）
- `'generate:...'` — 无 Django 模型对应（chapters 表从 Document.chapter GROUP BY 生成）
- `'lecture_transform'` — Document → lecture_content 自定义转换

### build_assets.py

```
1. 读取 ASSETS_TABLES
2. 创建 in-memory SQLite DB（可以用 :memory: 或 tempfile）
3. 逐表处理：
   - direct: Model.objects.all().values() → 批量 INSERT
   - m2m: 遍历关系 → 写入中间表
   - relation: 遍历 BaseQuestion → SolutionStep.card_titles → KnowledgeCard
4. 创建 _meta 表（schema_version / data_version / checksum / built_at）
5. 计算整个 .db 文件的 SHA-256
6. gzip 压缩到 media/db/qbank_v{version}.db.gz
7. 更新 DbVersion 记录
```

### build_lectures.py

```
1. 读取 LECTURE_TABLES
2. chapter 表：Document.objects.values('course_id', 'chapter').distinct() → 生成
3. lecture_content：Document → 改表名、关联 chapter_id
4. 同 assets 流程
```

### 命令行参数

```bash
python scripts/build_assets.py           # 构建+更新版本号
python scripts/build_assets.py --test     # 仅构建，不更新版本号（开发验证用）
python scripts/build_lectures.py
python scripts/build_lectures.py --test
```

### 依赖包

需要 `pypng` 或 Pillow 处理图片？不需要，配图复制是文件操作。构建脚本仅需要 Python 标准库（sqlite3 / hashlib / gzip / json）。

### 验证方式

```bash
# 1. 构建测试
python scripts/build_assets.py --test
python scripts/build_lectures.py --test

# 2. 检查表结构
sqlite3 media/db/qbank_vN.db.gz ".tables"
# 应包含：question, choice_ext, sub_question, solution_method, solution_step,
#          concept_tag, knowledge_card, question_concept_tag, question_knowledge_card,
#          course, assignment, assignment_question, achievement_def, level_config, _meta

# 3. 行数对比
sqlite3 media/db/qbank_vN.db.gz "SELECT COUNT(*) FROM question"   # = 798
python -c "from qbank.models import BaseQuestion; print(BaseQuestion.objects.count())"
# 两个值应相等

# 4. 随机抽检
# 从产物取 5 条，与 Django ORM 查询对比
```

---

## 1.7 — PDF 视图（1 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/math_platform/settings.py` | 新增 PDF_SECRET_KEY 配置 |
| `server/interactions/pdf_views.py` | **新建**：PdfRequestTokenView + pdf_view |
| `server/interactions/urls.py` | 新增 pdf/ 路由 |
| `server/math_platform/urls.py` | 新增 `/pdf/view/` 路由（非 api/v1 前缀） |
| `server/templates/pdf/paper_view.html` | **新建**：PDF 渲染模板 |
| `server/static/fonts/.gitkeep` | **新建**（字体占位） |
| `server/interactions/tests/test_pdf.py` | **新建**：PDF API 测试 |

### PDF_SECRET_KEY

```python
# settings.py
PDF_SECRET_KEY = config('PDF_SECRET_KEY', default='')
```

在 `.env` 中生成（`python -c "import secrets; print(secrets.token_hex(32))"`）。

### PdfRequestTokenView（POST /api/v1/pdf/request-token/）

**请求体：** `{"source_id": 123, "source_type": "paper"}`

**流程：**
1. 从 JWT 解析 student_id
2. 查询对应数据源：
   - source_type=paper：`CustomPaper.objects.get(id=source_id)` → 校验归属（自己的或公开的）
   - source_type=assignment：`Assignment.objects.get(id=source_id)` → 校验班级
3. 生成 sig = `HMAC-SHA256(key=PDF_SECRET_KEY, data=f"{source_id}:{source_type}:{student_id}:{expire_timestamp}")`
4. 返回 `{sig, expire_in:300, url: f"/pdf/view?pid={source_id}&type={source_type}&sig={sig}"}`

### pdf_view（GET /pdf/view）

**参数：** `pid`, `type`（默认 paper）, `sig`

**流程：**
1. 从 sig 解析 student_id + expire_timestamp
2. 验证签名（HMAC 重新计算对比）
3. 验证有效期（不超过 5 分钟）
4. 查询题目列表（via CustomPaperQuestion / AssignmentQuestion）
5. 查询 choice_ext（选项）、question.images（配图路径）
6. 查询 student 信息（昵称+学号）
7. 渲染 HTML

### HTML 模板（paper_view.html）

**排版规范（见 PDF方案设计.md 第四章）：**
- A4 纸张，`@page{size:A4; margin:2.54cm 3.17cm}`
- Noto Serif CJK SC + Latin Modern Roman 字体栈（先用系统字体走通，子集化后续优化）
- KaTeX（先用 CDN：`cdn.jsdelivr.net/npm/katex`）
- 选择/填空连续排版，解答题每题起页
- 图片靠右浮动 max-width 180px
- 页脚：左「章鱼智学」、中页码 `— N —`、右昵称+学号
- 学生个人信息在页脚通过模板变量注入

**初始简化：** 先走通流程，字体用系统 SimSun/STSong 兜底，不一开始就做字体子集化。

### 验证方式

手动测试流程：
1. 获取 access_token（登录）
2. 请求 `POST /api/v1/pdf/request-token/` → 获得 sig + url
3. 浏览器打开完整 URL → 看到 HTML 渲染含 KaTeX 公式
4. 浏览器打印预览 → 确认 A4 排版
5. 测试过期签名 → 403 错误页
6. 测试无权限 → 403 错误页

---

## 1.8 — Admin system/tools 页面（0.5 天）

### 涉及文件

| 文件 | 变更 |
|------|------|
| `server/system/admin.py` | 新增 ToolsAdminView（自定义 Admin 视图） |
| `server/system/templates/admin/system/tools.html` | **新建**：工具页面模板 |
| `server/system/urls.py` | 新增 tools/ 管理路由 |

### 功能

**构建按钮区：**
- 「构建并发布 · 题库」— 调 build_assets.py，更新 DbVersion
- 「构建并发布 · 讲义」— 调 build_lectures.py，更新 DbVersion
- 「仅构建测试 · 题库」— 调 build_assets.py --test
- 「仅构建测试 · 讲义」— 调 build_lectures.py --test

**邀请码管理区：**
- 「生成邀请码」— 表单：数量、有效期，批量创建 InvitationCode
- 显示当前有效邀请码列表（code + 创建时间 + 状态）

**批量导入区（占位）：**
- CSV 导入学生名单表单（占位，功能在教师 Web 端实现）

### 实现方式

使用 Django Admin 的 `change_view` 或自定义 `AdminSite.register` 方式。最简单的方案：

```python
# system/admin.py
from django.urls import path
from django.shortcuts import render
from django.contrib import admin
from django.contrib.admin.views.decorators import staff_member_required
from django.utils.decorators import method_decorator
from django.views import View

@method_decorator(staff_member_required, name='dispatch')
class ToolsView(View):
    template_name = 'admin/system/tools.html'
    
    def get(self, request):
        return render(request, self.template_name, {
            'db_versions': DbVersion.objects.all(),
            'invitation_codes': InvitationCode.objects.order_by('-created_at')[:20],
        })
    
    def post(self, request):
        action = request.POST.get('action')
        if action == 'build_assets':
            # 调用构建函数
            ...
        elif action == 'generate_codes':
            ...
        return redirect('...')
```

然后在 App 的 `get_urls()` 中注册：
```python
# system/admin.py
class SystemAdminSite(admin.AdminSite):
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('tools/', self.admin_view(ToolsView.as_view()), name='tools'),
        ]
        return custom_urls + urls
```

### 各 App admin.py 基础配置

**accounts/admin.py：**
```python
@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['user', 'class_group', 'get_username']
    search_fields = ['user__username', 'user__real_name']

@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    list_display = ['user', 'get_username']

@admin.register(InvitationCode)
class InvitationCodeAdmin(admin.ModelAdmin):
    list_display = ['code', 'is_used', 'expires_at', 'created_at']
    list_filter = ['is_used']
```

其他 Admin 类似，配置 list_display/search_fields/list_filter/filter_horizontal（M2M）。

### 验证方式

- 浏览器打开 `/admin/system/tools/` → 页面渲染
- 点击构建按钮 → media/db/ 目录下生成文件
- 邀请码生成 → InvitationCode 表新增记录

---

## 执行顺序与依赖

```
1.1 models.py ← 基础，无前置依赖
  ↓
1.2 题库迁移 ← 依赖 1.1（模型就绪）
  ↓
1.3 认证 API ← 依赖 1.1（User/Student/Teacher 模型），与 1.2 可并行
  ↓
1.4 同步 API ← 依赖 1.1 + 1.2
  ↓
1.5 用户/组卷 API ← 依赖 1.3
  ↓
1.6 构建脚本 ← 依赖 1.1 + 1.2
  ↓
1.7 PDF 视图 ← 依赖 1.5
  ↓
1.8 Admin tools ← 依赖 1.6 + 1.7
```

**可并行的路径：**
- 1.2（题库迁移）与 1.3（认证 API）可同时进行
- 1.6（构建脚本）与 1.5（用户 API）可同时进行
- 1.8（Admin tools）在 1.6/1.7 任一完成后可启动

---

## 测试计划

| 步骤 | 测试内容 | 类型 | 方式 |
|------|---------|------|------|
| 1.1 | migrate 通过、check 零问题、Admin 可访问 | smoke | 手动运行命令 |
| 1.2 | 题数 798、5 题逐字段抽检、配图数量 | 数据验证 | 脚本自验 + 手动观察 |
| 1.3 | 注册/登录/刷新/失败 4 场景 | 契约 | pytest |
| 1.4 | 版本检查×2、sync push 6 种 entity | 契约 | pytest |
| 1.5 | 用户信息/头像/课程/讲义 各端点 | 契约 | pytest |
| 1.6 | 表结构完整、行数匹配、checksum | 数据验证 | sqlite3 CLI + 脚本 |
| 1.7 | sig 验证、HTML 渲染、权限错误 | 手动 | 浏览器操作 |
| 1.8 | 页面加载、按钮功能 | 手动 | Admin 页面操作 |


---

**相关文档：**
- [数据库结构设计.md](../02-数据/数据库结构设计.md) — 表定义
- [API设计.md](../03-服务端/API设计.md) — 全部端点规范
- [服务端架构.md](../03-服务端/服务端架构.md) — App 划分与部署
- [构建脚本设计.md](../02-数据/构建脚本设计.md) — 构建流程
- [PDF方案设计.md](../03-服务端/PDF方案设计.md) — PDF 渲染流程
