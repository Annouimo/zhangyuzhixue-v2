# 章鱼智学 · API 设计

> 本文档定义新版 Django 服务端所有 API 端点的规范、请求/响应格式、错误码体系与分页策略。
>
> **状态**：设计阶段，未落地。
>
> **前置文档**：[服务端架构.md](../03-服务端/服务端架构.md) | [数据库结构设计.md](../02-数据/数据库结构设计.md) | [本地数据架构.md](../02-数据/本地数据架构.md)

---

## 一、通用规范

### 1.1 统一响应格式

所有 API 响应统一使用以下外壳：

**成功响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": { … }
}
```

**错误响应：**
```json
{
  "code": 40001,
  "message": "用户名或密码错误",
  "data": null
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | int | 0 = 成功，非 0 = 错误码 |
| `message` | string | 成功时为 `"ok"`，失败时为人类可读的错误描述 |
| `data` | any | 成功时携带负载，失败时为 `null` |

### 1.2 错误码体系

| 范围 | 类别 | 示例 |
|------|------|------|
| `40001` – `40099` | 认证错误 | 40001=用户名或密码错误, 40002=Token 过期, 40003=无权限 |
| `40101` – `40199` | 注册与邀请码 | 40101=邀请码无效, 40102=用户名已存在 |
| `40201` – `40299` | 业务校验 | 40201=参数不完整 |
| `40301` – `40399` | 同步错误 | 40301=无效 payload, 40302=版本冲突 |
| `50001` – `50099` | 服务端错误 | 50001=内部错误 |

### 1.3 认证头

```http
Authorization: Bearer ***
```

Flutter 端通过拦截器全局注入。Token 过期时返回 `code=40002`，客户端自动调用 `/api/v1/auth/refresh/` 续期后重试。

### 1.4 分页规范

需要分页的列表端点统一使用：

**请求参数：**
| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `page` | int | 1 | 页码，从 1 开始 |
| `page_size` | int | 20 | 每页条数，最大 100 |

**响应格式（data 内部）：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [ … ],
    "total": 142,
    "page": 1,
    "page_size": 20,
    "total_pages": 8
  }
}
```

列表为空时 `items` 返回空数组 `[]`，不返回 `null`。

### 1.5 日期格式

所有日期时间字段统一使用 ISO 8601 字符串：`"2026-07-09T14:30:00+08:00"`

---

## 二、认证 API

> 对应 App：`accounts`

### 2.1 登录

```
POST /api/v1/auth/login/
```

**请求体：**
```json
{
  "username": "zhangsan",
  "password": "***",
  "app_type": "student"
}
```

**响应 `code=0`：**
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
      "student_id": "G2026001",
      "class_group_id": 2,
      "school": "北京四中",
      "gaokao_year": 2026,
      "avatar": null
    }
  }
}
```

**说明：**
- `app_type` 取值 `student` / `teacher`，用于角色校验
- `user.role` 由服务端根据 `Student` / `Teacher` 表是否存在推断
- 登录成功后，Flutter 端将 `user` 缓存到 SharedPreferences（快速路由用）
- 管理员不登录 Flutter App，`app_type` 传 `student` 或 `teacher` 时管理员账号会被拒绝

**错误码：**
| 错误码 | 条件 |
|--------|------|
| 40001 | 用户名或密码错误 |
| 40003 | `app_type` 与用户角色不匹配（如 student 账号尝试 teacher 登录）|

### 2.2 注册（仅学生）

```
POST /api/v1/auth/register/
```

**请求体：**
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

**响应 `code=0`：**
```json
{
  "code": 0,
  "message": "注册成功，请登录",
  "data": null
}
```

**说明：**
- 注册**不直接返回 token**，成功后客户端跳转登录页
- `real_name` 必填，`phone` 和 `gaokao_year` 可选
- 成功时自动创建 `User` + `Student` 记录，`Student.class_group` 初始为 `null`（管理员后续手动拉入班级）

**错误码：**
| 错误码 | 条件 |
|--------|------|
| 40101 | 邀请码无效/已使用/已过期 |
| 40102 | 用户名已存在 |

### 2.3 Token 刷新

```
POST /api/v1/auth/refresh/
```

**请求体：**
```json
{
  "refresh": "eyJhbG..."
}
```

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "access": "eyJhbG...",
    "refresh": "eyJhbG..."
  }
}
```

**说明：**
- 返回新的 access + refresh pair（refresh 也轮换，simplejwt 默认行为）
- 刷新失败返回 `code=40002`，客户端清除所有 token 跳转登录页

### 2.4 登出

```
POST /api/v1/auth/logout/
```

**说明：** JWT 无状态，服务端不做额外操作。客户端清除 SharedPreferences 中的 token 和 user 缓存即可。

---

## 三、同步 API

> 对应 App：各 App 按 entity 归属处理 sync push

### 3.1 题库版本检查

```
GET /api/v1/sync/qbank/version/
```

**说明：** 无参，无需认证（App 在登录前也可能检查版本）。

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "schema_version": 1,
    "data_version": 5,
    "force_update": true,
    "message": "新增2025年高考真题，修正3处解析错误",
    "download_url": "/media/db/qbank_v5.db.gz",
    "checksum": "sha256:e3b0c44...",
    "size_bytes": 4194304
  }
}
```

**说明：**
- `schema_version` — 客户端硬编码，不匹配时必须去商店更新 App
- `data_version` — 管理端上传 .db 时标注
- `force_update` — 管理端标注，或客户端本地版本落后 ≥3 版时客户端自行升级为强制
- `download_url` — nginx 直接 serve 的文件路径
- `checksum` — SHA-256 校验，防下载损坏
- 客户端无 access token 时此接口也应返回数据（版本检查在登录前就需要）

### 3.2 讲义版本检查

```
GET /api/v1/sync/lecture/version/
```

**说明：** 与题库版本检查完全相同的响应格式，仅 data 含义不同。

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "schema_version": 1,
    "data_version": 8,
    "force_update": false,
    "message": "更新第5讲内容，新增2道例题",
    "download_url": "/media/db/lecture_v8.db.gz",
    "checksum": "sha256:a1b2c3d...",
    "size_bytes": 2097152
  }
}
```

### 3.3 同步推送（学生端 → 服务端）

```
POST /api/v1/sync/push/
```

**认证：** 需要 Bearer token

**请求体：**
```json
{
  "batch": [
    {
      "entity_type": "submission",
      "operation_type": "create",
      "payload": {
        "student_id": 1,
        "assignment_id": null,
        "submission_details": [
          {
            "question_id": 42,
            "answer_text": "A",
            "is_correct": true
          }
        ]
      }
    },
    {
      "entity_type": "step_feedback",
      "operation_type": "create",
      "payload": {
        "submission_detail_id": null,
        "question_id": 42,
        "sub_question_index": 0,
        "method_id": 1,
        "step_number": 3,
        "status": "full_correct"
      }
    }
  ]
}
```

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "server_ids": {
      "submission": {
        "local_1": 1001
      },
      "step_feedback": {
        "local_2": 5001
      }
    }
  }
}
```

**说明：**
- 客户端将本地的 `sync_queue` 表中 `pending` 状态的条目批量组包推送
- 每条 payload 中的 `student_id` 由服务端从 token 解析，**忽略请求体中的 `student_id`**（防篡改）
- `submission_detail_id` 等本地引用字段：首次推送时为 `null`；服务端处理完 submission 后生成 server_id，回填到响应的 `server_ids` 中
- 服务端按 `batch` 数组顺序处理，保证 submission 在 detail 之前
- 同一 batch 内的所有操作在同一事务中完成

**错误码：**
| 错误码 | 条件 |
|--------|------|
| 40301 | payload 校验失败（缺少必填字段）|
| 40302 | LWW 冲突（`updated_at` 比服务端旧，跳过此次更新）|

#### 推送数据流

```
客户端操作 → 写入 user.db（即时响应）
          → 追加 sync_queue 表（pending）
          → 下次启动或手动触发推送
          → POST /api/v1/sync/push/
          → 服务端接收，写入 Django DB
          → 返回 server_ids
          → 客户端回填 server_id，标记 done
```

#### 推送粒度（batch 内条目）

| 用户操作 | batch 内容 |
|---------|-----------|
| 做完一道选填题 | 1 × submission (含 1 个 submission_detail) |
| 做完一道解答题 | 1 × submission (含 1 个 detail) + N × step_feedback + M × card_feedback |
| 评分 | 1 × rating |
| 创建组卷 | 1 × custom_paper (含 N 个 paper_question) |
| 点赞/收藏 | 1 × paper_like / paper_collect |

#### 推送时机

App 启动时 + 用户手动触发。"全部重试"按钮即遍历所有 `pending`/`failed` 状态的队列条目执行推送。

---

## 四、PDF API

> 对应 App：`interactions`（新增 `pdf_urls.py` + `pdf_views.py`）

### 4.1 请求 PDF 浏览 token

```
POST /api/v1/pdf/request-token/
```

**认证：** 需要 Bearer token（JWT access_token）

**请求体：**
```json
{
  "paper_id": 123
}
```

**响应 `code=0`：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "sig": "a1b2c3d4e5f67890abcdef1234567890abcdef12",
    "expire_in": 300,
    "url": "/pdf/view?pid=123&sig=a1b2c3d4e5f67890abcdef1234567890abcdef12"
  }
}
```

**字段说明：**
| 字段 | 类型 | 说明 |
|------|------|------|
| `sig` | string | HMAC-SHA256 签名，hex 编码，40 字符 |
| `expire_in` | int | 有效期秒数，固定 300（5 分钟） |
| `url` | string | 相对路径，Flutter 端拼接域名后通过 `url_launcher` 打开 |

**服务端 sig 生成逻辑：**
```python
import hmac, hashlib, time
data = f"{paper_id}:{student_id}:{int(time.time()) + 300}"
sig = hmac.new(PDF_SECRET_KEY.encode(), data.encode(), hashlib.sha256).hexdigest()
```

**说明：**
- 服务端从 JWT access_token 解析 `student_id`（学生身份）
- `paper_id` 必须属于该学生（`custom_paper.student = student`）或是公开试卷
- 生成的 sig 绑定 paper_id + student_id + expire_timestamp 三元组，不可跨学生使用
- Flutter 端收到 sig 后应立即打开 URL，不缓存

**错误码：**
| 错误码 | 条件 |
|--------|------|
| 40003 | 无权访问该试卷（不属于当前学生且非公开） |
| 40201 | paper_id 不存在 |
| 50001 | 服务端内部错误 |

---

## 五、用户 API


> 对应 App：`accounts`

### 4.1 当前用户信息

```
GET /api/v1/user/me/
```

**认证：** 需要 Bearer token

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": 1,
    "username": "zhangsan",
    "real_name": "张三",
    "role": "student",
    "student_id": "G2026001",
    "class_group_id": 2,
    "school": "北京四中",
    "gaokao_year": 2026,
    "avatar": "https://zhangyuzhixue.top/media/avatars/1.webp",
    "phone": "138****8000",
    "points_summary": {
      "earned": 1280,
      "bonus": 100,
      "spent": 350,
      "available": 1030
    }
  }
}
```

**说明：**
- 登录成功后，Flutter 端将 `user` 缓存到 SharedPreferences
- `points_summary` 由服务端实时计算

### 4.2 更新用户信息

```
PATCH /api/v1/user/me/
```

**请求体（仅传要修改的字段）：**
```json
{
  "real_name": "张四",
  "phone": "13900139000"
}
```

**响应：** 返回更新后的完整用户信息（同 4.1）

**不允许通过此接口修改的字段：** `username`、`role`、`points_summary`

### 4.3 头像上传

```
POST /api/v1/user/avatar/
```

**请求体：** `multipart/form-data`
```
avatar: <binary image data>
```

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "avatar": "https://zhangyuzhixue.top/media/avatars/1.webp"
  }
}
```

**说明：**
- 服务端自动 resize 为 200×200，转码为 WebP
- 不走 sync_queue（二进制文件不混入 JSON 推送体）
- 上传成功后客户端更新本地 `user_profile.avatar` 字段
- 限制最大 2MB

### 4.4 等级百分位

```
GET /api/v1/user/level-percentile/
```

**认证：** 需要 Bearer token

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "level": 5,
    "title": "青铜学徒",
    "total_xp": 1280,
    "level_percentile": 68.5
  }
}
```

**说明：**
- `level_percentile` = 当前用户累计积分超过的百分比（如 68.5 = 超过 68.5% 的用户）
- 需要全量用户数据计算，必须调服务端 API，本地无法计算
- 数据缓存在客户端，缓存过期策略后续决定

---

## 六、教师 API

> 对应 App：`courses` + `accounts` + `interactions` 的跨 App 数据拼装

### 5.1 作业列表

```
GET /api/v1/teacher/assignments/?page=1&page_size=20
```

**认证：** 需要 Bearer token + user 是 teacher

**响应（分页格式）：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "导数基础练习",
        "class_name": "高三1班",
        "course_name": "导数系统课",
        "question_count": 10,
        "deadline": "2026-07-15T23:59:59+08:00",
        "completed_count": 18,
        "total_count": 32,
        "completion_rate": 56.3,
        "publish_at": "2026-07-09T10:00:00+08:00"
      }
    ],
    "total": 5,
    "page": 1,
    "page_size": 20,
    "total_pages": 1
  }
}
```

### 5.2 发布作业

```
POST /api/v1/teacher/assignments/
```

**认证：** 需要 Bearer token + teacher

**请求体：**
```json
{
  "title": "导数基础练习",
  "description": "选填题为主，巩固导数概念",
  "course_id": 1,
  "class_ids": [1, 2],
  "question_ids": [42, 43, 44, 45, 46, 47, 48, 49, 50, 51],
  "deadline": "2026-07-15T23:59:59+08:00"
}
```

**响应 `code=0`：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": 1,
    "title": "导数基础练习",
    "question_count": 10,
    "target_class_count": 2,
    "target_student_count": 32
  }
}
```

**服务端操作（事务内）：**
1. 创建 `Assignment` 记录
2. 为 `question_ids` 批量创建 `AssignmentQuestion`
3. 为 `class_ids` + `Assignment` 批量创建 `ClassCourseAssignment`
4. `publish_at` 自动设为当前时间

### 5.3 作业详情（按学生）

```
GET /api/v1/teacher/assignments/{id}/
```

**认证：** 需要 Bearer token + teacher

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": 1,
    "title": "导数基础练习",
    "description": "选填题为主",
    "deadline": "2026-07-15T23:59:59+08:00",
    "question_count": 10,
    "classes": [
      {
        "class_id": 1,
        "class_name": "高三1班",
        "students": [
          {
            "student_id": 1,
            "real_name": "张三",
            "submitted": true,
            "correct_count": 8,
            "total_count": 10,
            "accuracy": 80.0,
            "submitted_at": "2026-07-09T14:30:00+08:00"
          }
        ],
        "summary": {
          "total": 32,
          "submitted": 18,
          "average_accuracy": 72.5
        }
      }
    ]
  }
}
```

### 5.4 修改/删除作业

```
PATCH /api/v1/teacher/assignments/{id}/
DELETE /api/v1/teacher/assignments/{id}/
```

**认证：** 需要 Bearer token + teacher

`PATCH` 允许修改字段：`title`, `description`, `deadline`（不允许修改题目列表和班级，如需修改建议删除重建）

### 5.5 作业催交

```
POST /api/v1/teacher/assignments/{id}/remind/
```

**认证：** 需要 Bearer token + teacher

**说明：** 暂无通知推送通道，当前仅记录催交日志，预留未来扩展。

### 5.6 班级列表

```
GET /api/v1/teacher/classes/
```

**认证：** 需要 Bearer token + teacher

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [
      {
        "id": 1,
        "name": "高三1班",
        "student_count": 32,
        "course_count": 3,
        "average_accuracy": 73.2,
        "total_questions_done": 2840
      }
    ]
  }
}
```

### 5.7 学生列表

```
GET /api/v1/teacher/students/?search=张三&class_id=1&page=1&page_size=20
```

**认证：** 需要 Bearer token + teacher

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [
      {
        "id": 1,
        "real_name": "张三",
        "class_name": "高三1班",
        "total_questions": 156,
        "correct_count": 118,
        "accuracy": 75.6,
        "streak_days": 7
      }
    ],
    "total": 32,
    "page": 1,
    "page_size": 20,
    "total_pages": 2
  }
}
```

**参数：**
| 参数 | 类型 | 说明 |
|------|------|------|
| `search` | string | 按姓名/学号搜索 |
| `class_id` | int | 按班级筛选 |

### 5.8 学生详情

```
GET /api/v1/teacher/students/{id}/
```

**认证：** 需要 Bearer token + teacher

**响应：**
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": 1,
    "real_name": "张三",
    "class_name": "高三1班",
    "student_id": "G2026001",
    "total_questions": 156,
    "accuracy": 75.6,
    "streak_days": 7,
    "accuracy_trend": [
      {"date": "2026-07-03", "accuracy": 72.0, "count": 5},
      {"date": "2026-07-04", "accuracy": 80.0, "count": 8}
    ],
    "weak_tags": [
      {"tag_name": "函数·零点", "accuracy": 50.0, "count": 6},
      {"tag_name": "导数·单调性", "accuracy": 60.0, "count": 10}
    ],
    "question_type_breakdown": [
      {"type": "选择题", "count": 80, "accuracy": 82.5},
      {"type": "填空题", "count": 40, "accuracy": 70.0},
      {"type": "解答题", "count": 36, "accuracy": 65.3}
    ]
  }
}
```

**说明：**
- `accuracy_trend` 返回最近 30 天每日正确率（有做题的日子才有一条）
- `weak_tags` 按正确率升序排列（最弱的在最前），取 top 10

---

## 七、讲义 API

> 对应 App：`courses`

讲义 API 用于课程列表、章节目录和讲义内容的获取。客户端以 lectures.db 作为主要数据源，API 用于首次获取或更新。

### 6.1 课程列表

```
GET /api/v1/lectures/courses/
```

**响应：**
```json
[
  {"id": 1, "name": "导数系统课", "chapter_count": 12},
  {"id": 2, "name": "三角函数专项", "chapter_count": 8}
]
```

### 6.2 章节目录

```
GET /api/v1/lectures/courses/{courseId}/chapters/
```

**响应：**
```json
{
  "course_name": "导数系统课",
  "items": [
    {"id": 1, "title": "导数的概念与运算", "page_count": 8},
    {"id": 2, "title": "导数的几何意义", "page_count": 6}
  ]
}
```

说明：`page_count` 由服务端从 `md_content` 解析计算（按 `<!-- pagebreak -->` 切分后长度），客户端不依赖该值精确性。

### 6.3 讲义内容

```
GET /api/v1/lectures/chapters/{chapterId}/content/
```

**响应：**
```json
{
  "chapter_id": 1,
  "title": "导数的几何意义",
  "md_content": "## 一、导数的几何意义\n函数 y = f(x) ...\n<!-- reveal -->\n**例 1**..."
}
```

说明：`md_content` 为 `Document.md_content` 原样返回，不做解析。客户端渲染器 `parseMdContent()` 在本地按分隔符解析为分页+展开结构。

---

## 八、共用端点汇总

### 7.1 端点清单

| 方法 | 端点 | 角色 | 说明 |
|------|------|------|------|
| `POST` | `/api/v1/auth/login/` | 无 | 登录 |
| `POST` | `/api/v1/auth/register/` | 无 | 注册 |
| `POST` | `/api/v1/auth/refresh/` | 无 | Token 刷新 |
| `POST` | `/api/v1/auth/logout/` | 任意 | 登出 |
| `GET` | `/api/v1/sync/qbank/version/` | 无 | 题库版本检查 |
| `GET` | `/api/v1/sync/lecture/version/` | 无 | 讲义版本检查 |
| `POST` | `/api/v1/sync/push/` | student | 同步推送 |
| `GET` | `/api/v1/user/me/` | 任意 | 当前用户信息 |
| `PATCH` | `/api/v1/user/me/` | 任意 | 更新用户信息 |
| `POST` | `/api/v1/user/avatar/` | 任意 | 上传头像 |
| `GET` | `/api/v1/user/level-percentile/` | student | 等级百分位 |
| `GET` | `/api/v1/lectures/courses/` | student | 课程列表 |
| `GET` | `/api/v1/lectures/courses/{courseId}/chapters/` | student | 章节目录 |
| `GET` | `/api/v1/lectures/chapters/{chapterId}/content/` | student | 讲义内容 |
| `GET` | `/api/v1/teacher/assignments/` | teacher | 作业列表 |
| `POST` | `/api/v1/teacher/assignments/` | teacher | 发布作业 |
| `GET` | `/api/v1/teacher/assignments/{id}/` | teacher | 作业详情 |
| `PATCH` | `/api/v1/teacher/assignments/{id}/` | teacher | 修改作业 |
| `DELETE` | `/api/v1/teacher/assignments/{id}/` | teacher | 删除作业 |
| `POST` | `/api/v1/teacher/assignments/{id}/remind/` | teacher | 催交 |
| `GET` | `/api/v1/teacher/classes/` | teacher | 班级列表 |
| `GET` | `/api/v1/teacher/students/` | teacher | 学生列表 |
| `GET` | `/api/v1/teacher/students/{id}/` | teacher | 学生详情 |

### 7.2 不需要 API 的功能（确认清单）

以下功能在 Flutter v2 架构中**全部在本地完成**，不走服务端 API：

| 功能 | 数据源 | 说明 |
|------|--------|------|
| 题目浏览与搜索 | assets.db | 预置在客户端 |
| 题目解答（题干/步骤/卡片） | assets.db | 预置在客户端 |
| 讲义阅读 | lectures.db | 预置在客户端 |
| 作业列表查看 | assets.db + user.db | 作业定义在 assets，完成状态从 user.db 推算 |
| 推荐算法 | assets.db + user.db | 本地计算，服务端不参与 |
| 组卷（创建/预览） | assets.db + user.db | 本地计算 |
| 积分计算 | user.db | `_PointsCalculator` 在本地实时计算 |
| 成就推算 | assets.db + user.db | `_AchievementEngine` 在本地推算 |
| 学习统计 | user.db | `_StatisticsAggregator` 本地聚合 |
| 筛选预设 | user.db（preference_filter）| 纯本地数据 |

---

## 九、API 版本控制

所有 API 端点统一使用 `/api/v1/` 前缀。理由：

- API 变更和 App 发版是两个节奏：App 要商店审核，API 随时可上线
- 旧版 App 在用户手机上可能存在数周甚至数月，API 不一定能向下兼容
- 加前缀是 Django 里 `include(prefix='v1/')` 一行的事，零维护成本
- 行业惯例，清晰表达接口契约版本

**示例：**
```
POST /api/v1/auth/login/
GET  /api/v1/sync/qbank/version/
POST /api/v1/sync/push/
GET  /api/v1/teacher/assignments/
```

> 数据版本（assets.db 的 data_version）与 API 版本无关，各自独立演进。

---

## 十、路由文件组织

```python
# math_platform/urls.py
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/', include('accounts.auth_urls')),
    path('api/v1/sync/', include('qbank.urls')),
    path('api/v1/sync/', include('interactions.urls')),
    path('api/v1/user/', include('accounts.user_urls')),
    path('api/v1/lectures/', include('courses.urls')),
    path('api/v1/teacher/', include('courses.urls')),
]
```

> 实际实现时按 App 拆分 `urls.py`，最终在项目级 `urls.py` 中汇总。

---

> 相关文档：
> - [服务端架构.md](服务端架构.md) — 服务端 App 划分与部署
> - [数据库结构设计.md](../02-数据/数据库结构设计.md) — 数据库表定义
> - [同步引擎设计.md](../05-Flutter/同步引擎设计.md) — 同步队列设计
