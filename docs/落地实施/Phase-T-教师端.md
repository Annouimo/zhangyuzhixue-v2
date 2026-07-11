# Phase T — 教师 Web 端（~3 天，与 Phase 1-3 并行）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中「教师端」的细化执行方案。
> 教师端是轻量 Web SPA（纯静态 HTML/CSS/JS，nginx 直出），与服务端和 Flutter 端零代码依赖。
> 状态：**已完成** | 最后更新：2026-07-11

---

## 总览

| 子步骤 | 内容 | 工时 | 开工条件 | 状态 |
|:-------|:-----|:-----|:---------|:----:|
|| **TS.1** | 服务端教师 API（9 端点 + ~20 测试） | 0.6 天 | 模型/权限已就位 | ✅ |
|| **T.1** | 教师 Web 框架（nginx 路由 + 登录页 + JWT 认证） | 0.3 天 | Phase 1.3 认证 API 就绪 | ✅ |
|| **T.2** | 作业列表（主页）+ 发布作业（选组卷→设班级/日期→发布） | 0.8 天 | TS.1 完成后（教师 API 就绪） | ✅ |
|| **T.3** | 作业详情（按学生列完成状态） | 0.4 天 | 同上 | ✅ |
|| **T.4** | 班级概览（汇总统计卡片）+ 学生列表（搜索/筛选） | 0.5 天 | 同上 | ✅ |
|| **T.5** | 学生详情（个人报告 + 正确率趋势图） | 0.5 天 | 同上 | ✅ |
||| **T.6** | 关于页 | 0.15 天 | 共用用户 API | ✅ |
|| **T.7** | 集成测试 + 部署到 landing/teacher/ | 0.2 天 | T.1–T.6 完成 | ✅ |
| | **合计** | **~3.6 天** | | |

### 设计原则

| 原则 | 说明 |
|:-----|:------|
| **纯静态** | 无 Vue/React 等前端框架，无 npm/node_modules，无构建步骤。纯 HTML + CSS + Vanilla JS |
| **无离线能力** | 不做 PWA、不做 localStorage 数据缓存。每次页面加载从 API 拉取最新数据 |
| **nginx 直出** | 不经过 Django。`landing/teacher/` 目录下的静态文件由 nginx 直接 serve |
| **数据源唯一** | 所有数据通过 REST API（`/api/v1/teacher/*`）实时获取，不写本地数据库 |
| **JWT 无状态** | Token 存 localStorage。页面刷新后从 localStorage 读取 token 恢复会话 |

### 前置条件

- [x] Phase 1.3 完成：JWT 认证 API 就绪（login/refresh）
- [x] Phase 1.4 完成：sync/push entity 分发就绪（组卷数据可推送）
- [x] TS.1 已完成：服务端教师专用 API 端点就绪（`/api/v1/teacher/*`）
- [x] 登录放开角色校验已在服务端实现
- [x] 至少一个教师测试账号（`teacher1 / test123`）

### 关键设计文档索引

| 文档 | 用途 |
|:-----|:------|
| [`教师端功能边界.md`](../06-教师端/教师端功能边界.md) | 角色定位、页面清单、API 定义、数据流 |
|| [`landing/teacher/*.html`](../landing/teacher/) | 8 个教师端 HTML 页面（登录/主页/发布/详情/班级/学生列表/学生详情/关于） |
| [`API设计.md`](../03-服务端/API设计.md) | 所有端点格式参考 |
| [`服务端架构.md`](../03-服务端/服务端架构.md) | nginx 配置、域名路由 |

---

## TS.1 — 服务端教师 API（0.6 天）

> 服务端 `/api/v1/teacher/*` 端点尚未实现（已验证 404），需在 Web 前端 T.2 开发前补充。
> 必须现有模型和权限类均已就位。

### 涉及文件

```
server/courses/
├── teacher_views.py          ← 新建：9 个视图函数（@api_view + @permission_classes）
├── teacher_serializers.py    ← 新建：请求/响应序列化器
├── teacher_urls.py           ← 新建：6 条路由
└── tests/
    └── test_teacher.py       ← 新建：pytest ~20 场景

server/math_platform/urls.py  ← 修改：api_v1 加一行 path('teacher/', ...)
```

### 实现要点

#### 路由挂载

```python
# math_platform/urls.py 的 api_v1 列表中加入第 8 行（system 之后）：
path('teacher/', include('courses.teacher_urls')),
```

```python
# courses/teacher_urls.py
urlpatterns = [
    path('assignments/', views.assignment_list_create, name='teacher-assignment-list'),
    path('assignments/<int:id>/', views.assignment_rud, name='teacher-assignment-detail'),
    path('papers/', views.paper_list, name='teacher-paper-list'),
    path('classes/', views.class_list, name='teacher-class-list'),
    path('students/', views.student_list, name='teacher-student-list'),
    path('students/<int:id>/', views.student_detail, name='teacher-student-detail'),
]
```

#### 端点实现

**① `GET /api/v1/teacher/papers/` — 组卷列表**

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def paper_list(request):
    papers = CustomPaper.objects.annotate(q_count=Count('paper_questions'))
    data = [{'id': p.id, 'title': p.title, 'questionCount': p.q_count,
             'createdAt': p.created_at} for p in papers.order_by('-created_at')]
    return _ok(data=data)
```

> `CustomPaper.student` 外键指向 Student，教师登录没有 Student 记录。当前开发阶段组卷少，直接返回全部。后续需在 CustomPaper 加 created_by_user 字段或放宽 SyncPushView 对教师的限制。

**② `GET /api/v1/teacher/classes/` — 班级概览**

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def class_list(request):
    groups = ClassGroup.objects.annotate(
        s_count=Count('students'),
    )
    items = []
    for g in groups:
        # 计算该班级平均正确率：从 SubmissionDetail 聚合
        items.append({
            'name': g.name, 'studentCount': g.s_count,
            'avgAccuracy': _calc_class_accuracy(g.id),
        })
    return _ok(data={
        'totalClasses': groups.count(),
        'totalStudents': sum(g.s_count for g in groups),
        'avgAccuracy': _calc_overall_accuracy(),
        'items': items,
    })
```

**③ `GET /api/v1/teacher/students/` — 学生列表**

支持 `?search=张三&class_id=1` 查询参数。

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def student_list(request):
    qs = Student.objects.select_related('user', 'class_group')
    search = request.query_params.get('search', '')
    class_id = request.query_params.get('class_id', '')
    if search:
        qs = qs.filter(
            Q(user__first_name__icontains=search) |
            Q(user__username__icontains=search)
        )
    if class_id.isdigit():
        qs = qs.filter(class_group_id=int(class_id))
    data = [{'id': s.id, 'name': s.user.first_name or s.user.username,
             'className': s.class_group.name if s.class_group else '',
             'totalQuestions': _count_student_submissions(s.id),
             'avgAccuracy': _calc_student_accuracy(s.id),
             'lastActive': _last_active_date(s.id)}
            for s in qs]
    return _ok(data=data)
```

**④ `GET /api/v1/teacher/students/{id}/` — 学生详情**

返回个人信息 + 概览卡片 + 正确率趋势（近30天）+ 薄弱知识点。

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def student_detail(request, id):
    s = get_object_or_404(Student.objects.select_related('user', 'class_group'), pk=id)
    # 概览卡片
    total_q = SubmissionDetail.objects.filter(submission__student=s).count()
    correct_q = SubmissionDetail.objects.filter(
        submission__student=s, is_correct=True).count()
    accuracy = round(correct_q / total_q * 100, 1) if total_q else 0
    # 近30天趋势
    from django.utils import timezone
    thirty_days_ago = timezone.now() - timedelta(days=30)
    trend = SubmissionDetail.objects.filter(
        submission__student=s, created_at__gte=thirty_days_ago
    ).extra(select={'date': "date(created_at)"}).values('date').annotate(
        total=Count('id'), correct=Count('id', filter=Q(is_correct=True))
    )
    # 薄弱知识点：从 StepFeedback 聚合
    return _ok(data={...})
```

**⑤ `GET /api/v1/teacher/assignments/` + `POST /api/v1/teacher/assignments/` — 作业列表 + 发布**

```python
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated, IsTeacher])
def assignment_list_create(request):
    if request.method == 'GET':
        # 统计汇总 + items 列表（含完成率/正确率）
        ...
    # POST
    serializer = CreateAssignmentSerializer(data=request.data)
    if not serializer.is_valid():
        return _err(40201, ...)
    data = serializer.validated_data
    paper = CustomPaper.objects.get(pk=data['paper_id'])
    assignment = Assignment.objects.create(title=data.get('title', paper.title))
    for i, q in enumerate(paper.questions.all()):
        AssignmentQuestion.objects.create(assignment=assignment, question=q, sort_order=i)
    for cid in data['class_ids']:
        cc = ClassCourse.objects.filter(class_group_id=cid).first()
        if cc:
            ClassCourseAssignment.objects.create(
                class_course=cc, assignment=assignment,
                deadline=data['deadline'], is_active=True,
            )
    return _ok(data={'id': assignment.id})
```

**⑥ `GET/DELETE/PATCH /api/v1/teacher/assignments/{id}/` — 作业详情/删除/修改**

- GET：返回作业信息 + `students[]` 数组（每人状态/正确率/耗时）
- DELETE：`ClassCourseAssignment.is_active = False`
- PATCH：更新 deadline/description

#### 需抽取的辅助函数

| 函数 | 用途 |
|------|------|
| `_calc_class_accuracy(class_group_id)` | 该班级所有学生平均正确率 |
| `_calc_overall_accuracy()` | 全校平均正确率 |
| `_count_student_submissions(student_id)` | 学生总提交题数 |
| `_calc_student_accuracy(student_id)` | 学生个人正确率 |
| `_last_active_date(student_id)` | 最近提交日期 |

#### 辅助工具函数（与 accounts/views.py 共用）

```python
def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})

def _err(code, message, http_status=status.HTTP_400_BAD_REQUEST):
    return Response({'code': code, 'message': message, 'data': None}, status=http_status)
```

### 验证方式

```bash
# 在本地或 staging 服务器执行：

# 1. 教师登录获取 token
TOKEN=$(curl -s -X POST 'https://zhangyuzhixue.top/api/v1/auth/login/' \
  -H 'Content-Type: application/json' \
  -d '{"username":"teacher1","password":"test123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['access'])")
echo "Token: ${TOKEN:0:20}..."

# 2. 验证组卷列表
curl -s -H "Authorization: Bearer $TOKEN" \
  'https://zhangyuzhixue.top/api/v1/teacher/papers/' | python3 -m json.tool

# 3. 验证班级列表
curl -s -H "Authorization: Bearer $TOKEN" \
  'https://zhangyuzhixue.top/api/v1/teacher/classes/' | python3 -m json.tool

# 4. 验证学生列表
curl -s -H "Authorization: Bearer $TOKEN" \
  'https://zhangyuzhixue.top/api/v1/teacher/students/' | python3 -m json.tool

# 5. 发布作业（需先有组卷和班级数据）
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"paper_id":1,"title":"测试作业","deadline":"2026-07-20","class_ids":[1,2]}' \
  'https://zhangyuzhixue.top/api/v1/teacher/assignments/' | python3 -m json.tool

# 6. 验证作业列表
curl -s -H "Authorization: Bearer $TOKEN" \
  'https://zhangyuzhixue.top/api/v1/teacher/assignments/' | python3 -m json.tool

# 7. 学生端 API 应拒绝教师（401 或 403）
curl -s -H "Authorization: Bearer $TOKEN" \
  'https://zhangyuzhixue.top/api/v1/auth/register/' | python3 -m json.tool
```

### pytest 测试覆盖

| 测试组 | 场景数 | 覆盖内容 |
|--------|--------|---------|
| papers | 2 | 空列表、有数据 |
| classes | 2 | 空、有班级 + 统计数据 |
| students list | 3 | 全量、按姓名搜索、按班级筛选 |
| student detail | 3 | 正常数据、无提交记录（零数据）、不存在的学生 404 |
| assignments list | 3 | 空列表、有数据（含完成率计算）、仅活跃作业 |
| assignments create | 3 | 正常发布、参数缺失（paper_id/deadline/class_ids）、不存在的 paper_id |
| assignments detail | 2 | 正常、不存在 |
| assignments delete | 1 | 软删除验证 |
| assignments patch | 1 | 修改 deadline |
| **合计** | **~20** | |

### 注意事项

- 所有端点用 `IsAuthenticated + IsTeacher` 权限类保护
- 辅助函数如 `_calc_class_accuracy` 放在 `teacher_views.py` 文件尾部（私有函数），不抽成独立 helper（仅本文件使用）
- 学生端 API（submit/rating/fb）受 `IsStudent` 保护，教师自动被拒，不需额外逻辑
- 如测试中需要批量建学生数据，用 `django.test.Client` + `setUpTestData` 类方法一次性建好
- 不需要新增数据库模型或字段——全部使用现有模型

---

## T.1 — 教师 Web 框架 + 登录页（0.3 天）

### 涉及文件

```
landing/teacher/
├── login.html                     # 新建（从 docs/06-教师端/html/login.html 复制）
├── teacher-styles.css             # 新建（从 docs/06-教师端/html/ 复制或编写）
├── teacher-common.js              # 新建：JWT 认证、API 调用基础函数、路由守卫
└── index.html                     # T.2 新建，T.1 仅占位
```

### 实现要点

**nginx 路由（T.1 时配置）：**

```nginx
# location /teacher/ → nginx 直出静态文件
location /teacher/ {
    alias /opt/zhangyuzhixue-v2/landing/teacher/;
    index index.html;
    try_files $uri $uri/ =404;
}
```

**teacher-common.js 核心功能：**

```javascript
// ── JWT 管理 ──
const TOKEN_KEY = 'teacher_access_token';
const REFRESH_KEY = 'teacher_refresh_token';
const USER_KEY = 'teacher_user_cache';

function getToken() { return localStorage.getItem(TOKEN_KEY); }
function saveToken(t) { localStorage.setItem(TOKEN_KEY, t); }
function clearAuth() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_KEY);
  window.location.href = '/teacher/login.html';
}

// ── API 调用封装 ──
const API_BASE = '/api/v1';

async function apiCall(path, options = {}) {
  const token = getToken();
  const resp = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  const body = await resp.json();
  if (body.code === 40002) {  // token 过期
    const refreshed = await tryRefresh();
    if (refreshed) return apiCall(path, options); // 重试
    clearAuth();
  }
  if (body.code !== 0) throw new Error(body.message);
  return body.data;
}

// ── Token 刷新 ──
async function tryRefresh() {
  const refresh = localStorage.getItem(REFRESH_KEY);
  if (!refresh) return false;
  try {
    const resp = await fetch(`${API_BASE}/auth/refresh/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh }),
    });
    const body = await resp.json();
    if (body.code === 0) {
      saveToken(body.data.access);
      return true;
    }
  } catch {}
  return false;
}

// ── 路由守卫 ──
function requireAuth() {
  if (!getToken()) window.location.href = '/teacher/login.html';
}
```

**登录页（login.html）：**

| 元素 | 实现 | 说明 |
|:-----|:-----|:-----|
| 用户名输入 | `<input id="username">` | `app_type="teacher"` |
| 密码输入 | `<input id="password" type="password">` | — |
| 登录按钮 | `onclick="handleLogin()"` | 调 POST `/api/v1/auth/login/` |
| 错误提示 | `<div id="error-msg">` | 隐藏/显示错误信息 |

```javascript
async function handleLogin() {
  const username = document.getElementById('username').value.trim();
  const password = document.getElementById('password').value;
  if (!username || !password) { showError('请输入用户名和密码'); return; }

  try {
    const resp = await fetch(`${API_BASE}/auth/login/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password, app_type: 'teacher' }),
    });
    const body = await resp.json();
    if (body.code !== 0) { showError(body.message); return; }

    saveToken(body.data.access);
    localStorage.setItem(REFRESH_KEY, body.data.refresh);
    localStorage.setItem(USER_KEY, JSON.stringify(body.data.user));
    window.location.href = '/teacher/';
  } catch (e) {
    showError('网络错误，请稍后重试');
  }
}
```

### 验证方式

```bash
# 本地打开浏览器访问 landing/teacher/login.html
# 输入 teacher1 / test123 → 登录成功 → 跳转 /teacher/
# 直接访问 /teacher/ 未登录 → 跳回 /teacher/login.html
```

### 注意事项

- 教师登录用 `app_type="teacher"`，但服务端已不做角色校验，不影响
- Token 刷新逻辑与学生端一致（共享 refresh 端点）
- 登出 = 清除 localStorage + 跳转登录页
- localStorage 的 key 用 `teacher_` 前缀，避免与学生 Flutter App 的 SharedPreferences 混淆（Web 端不装 Flutter，实际不会冲突，但作为编码习惯保持一致）

---

## T.2 — 作业列表（主页）+ 发布作业（0.8 天）

### 涉及文件

```
landing/teacher/
├── index.html                     # 新建（主页·作业列表）
├── publish.html                   # 新建（发布作业）
├── teacher-styles.css             # 修改（补充组件样式）
└── teacher-common.js              # 修改（补充教师 API 调用函数）
```

### 实现要点

#### 主页·作业列表（index.html）

来自 HTML 原型 `docs/06-教师端/html/index.html`：

**顶部统计栏（4 个卡片）：**

| data-db | API | 说明 |
|:--------|:----|:-----|
| `stats.totalAssignments` | `GET /api/v1/teacher/assignments/` | 总发布作业数 |
| `stats.activeAssignments` | 同上 | 进行中（未到截止日） |
| `stats.avgCompletionRate` | 同上 | 平均完成率 |
| `stats.avgAccuracy` | 同上 | 平均正确率 |

**作业列表：**

| 元素 | data-db |
|:-----|:--------|
| 列表循环 | `data-db-loop="teacher.assignments"` |
| 标题 | `data-db="teacher.assignments[].title"` |
| 班级 | `data-db="teacher.assignments[].className"` |
| 截止日期 | `data-db="teacher.assignments[].deadline"` |
| 完成率 | `data-db="teacher.assignments[].completionRate"` |

**API 响应示例（GET /api/v1/teacher/assignments/）：**

```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "id": 1,
        "title": "导数基础练习",
        "className": "高三(1)班",
        "deadline": "2026-07-18",
        "totalStudents": 42,
        "completedCount": 30,
        "completionRate": "71%",
        "avgAccuracy": "65%"
      }
    ],
    "totalAssignments": 12,
    "activeAssignments": 5,
    "avgCompletionRate": "76%",
    "avgAccuracy": "68%"
  }
}
```

#### 发布作业（publish.html）

来自 HTML 原型 `docs/06-教师端/html/publish.html`：

**流程：**

```
1. 选择组卷 → GET /api/v1/teacher/papers/
   └── 列表显示教师创建的所有组卷（标题、题数、创建时间）
2. 填写作业信息
   └── 标题（默认 = 组卷名）
   └── 截止日期（日期选择器）
   └── 说明/备注（可选）
3. 选择班级
   └── GET /api/v1/teacher/classes/
   └── 复选框列表，显示各班级名称和学生人数
4. 确认发布 → POST /api/v1/teacher/assignments/
   └── body: { paper_id, title, deadline, description, class_ids }
5. 成功 → 跳回作业列表
```

**关键 JS 逻辑：**

```javascript
async function loadPapers() {
  const papers = await apiCall('/teacher/papers/');
  // 渲染组卷列表（单选Radio）
}

async function loadClasses() {
  const classes = await apiCall('/teacher/classes/');
  // 渲染班级复选框
}

async function handlePublish() {
  const paperId = getSelectedPaperId();
  const title = document.getElementById('title').value;
  const deadline = document.getElementById('deadline').value;
  const classIds = getSelectedClassIds();

  if (!paperId || !deadline || classIds.length === 0) {
    showError('请选择组卷、截止日期和目标班级');
    return;
  }

  await apiCall('/teacher/assignments/', {
    method: 'POST',
    body: JSON.stringify({ paper_id: paperId, title, deadline, class_ids: classIds }),
  });

  window.location.href = '/teacher/';
}
```

### 验证方式

```bash
# 在浏览器中操作：
# 1. 登录 → 看到作业列表（有统计卡片和列表）
# 2. 点「发布作业」→ 看到组卷列表和班级列表
# 3. 填写信息 → 发布成功 → 回到列表看到新条目
```

### 注意事项

- 组卷数据来源：教师通过学生 Flutter App 创建组卷 → sync 推送到服务端 → `GET /teacher/papers/` 拉取
- 如果 sync 队列推进有延迟，publish.html 需要显示加载状态，避免教师看到空列表疑惑
- 班级列表：当前 3 人规模，教师可见全部班级（无权限隔离）
- 发布作业时 `class_ids` 为数组（支持一次发布到多个班级）

---

## T.3 — 作业详情（0.4 天）

### 涉及文件

```
landing/teacher/
├── detail.html                    # 新建（作业详情）
└── teacher-common.js              # 修改（如有需要）
```

### 实现要点

来自 HTML 原型 `docs/06-教师端/html/detail.html`：

**页面布局：**

```
[← 返回作业列表]

作业标题：导数基础练习
班级：高三(1)班 | 截止日期：2026-07-18
完成 30/42 (71%) | 平均正确率 65%

按学生列出：
┌──────┬──────┬──────┬──────┬──────┐
│ 姓名  │ 状态  │ 正确率│ 耗时  │ 操作  │
├──────┼──────┼──────┼──────┼──────┤
│ 张三  │ ✅   │ 80%  │ 12分  │ 查看  │
│ 李四  │ ⬜   │ —    │ —    │ —    │
└──────┴──────┴──────┴──────┴──────┘
```

| data-db | API |
|:--------|:----|
| `teacher.assignmentDetail.title` | `GET /api/v1/teacher/assignments/{id}/` |
| `teacher.assignmentDetail.students[]` | 同上（内嵌数组） |

### API 响应示例（GET /api/v1/teacher/assignments/{id}/）：

```json
{
  "code": 0,
  "data": {
    "id": 1,
    "title": "导数基础练习",
    "deadline": "2026-07-18",
    "className": "高三(1)班",
    "totalStudents": 42,
    "completedCount": 30,
    "avgAccuracy": "65%",
    "students": [
      {
        "id": 101,
        "name": "张三",
        "status": "completed",
        "accuracy": "80%",
        "duration": "12分钟",
        "completedAt": "2026-07-15 14:30"
      },
      {
        "id": 102,
        "name": "李四",
        "status": "pending",
        "accuracy": null,
        "duration": null,
        "completedAt": null
      }
    ]
  }
}
```

### 验证方式

```bash
# 从作业列表点击一项 → 进入详情页
# 检查：标题/班级/人数统计正确
# 检查：已做学生显示正确率，未做学生显示「待提交」
# 点击学生姓名 → 跳转到学生详情页
```

### 注意事项

- 作业详情是人员维度的视图（一个作业 × N 个学生），与 Flutter 端的题目维度不同
- 正确率 = 该学生在当前作业中的答题正确率
- 未做的学生显示「待提交」灰色状态

---

## T.4 — 班级概览 + 学生列表（0.5 天）

### 涉及文件

```
landing/teacher/
├── classes.html                   # 新建（班级概览）
├── students.html                  # 新建（学生列表）
└── teacher-common.js              # 修改（如有需要）
```

### 实现要点

#### 班级概览（classes.html）

来自原型 `docs/06-教师端/html/classes.html`：

```
[← 返回]

━━ 班级概览 ━━

┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ 总班级数   │ │ 总学生数  │ │ 总题量    │ │ 平均正确率│
│ 6 个      │ │ 256 人   │ │ 798 题   │ │ 68%      │
└──────────┘ └──────────┘ └──────────┘ └──────────┘

班级列表：
┌──────────┬──────┬──────┬──────┬──────┐
│ 班级名称  │ 人数  │ 平均  │ 讲题  │ 操作  │
│           │      │ 正确率│ 数量  │      │
├──────────┼──────┼──────┼──────┼──────┤
│ 高三(1)班 │ 42   │ 72%  │ 5     │ 查看  │
│ 高三(2)班 │ 40   │ 65%  │ 5     │ 查看  │
└──────────┴──────┴──────┴──────┴──────┘
```

| data-db | API 字段 |
|:--------|:---------|
| `stats.totalClasses` | `classes.summary.totalClasses` |
| `stats.totalStudents` | `classes.summary.totalStudents` |
| `stats.avgAccuracy` | `classes.summary.avgAccuracy` |
| `teacher.classList[].name` | `classes.items[].name` |
| `teacher.classList[].studentCount` | `classes.items[].studentCount` |

#### 学生列表（students.html）

来自原型 `docs/06-教师端/html/students.html`：

**搜索/筛选栏：** 搜索框（按姓名/用户名搜索）+ 班级下拉筛选。

**列表：**

| 元素 | data-db |
|:-----|:--------|
| 姓名 | `teacher.students[].name` |
| 班级 | `teacher.students[].className` |
| 做题量 | `teacher.students[].totalQuestions` |
| 正确率 | `teacher.students[].avgAccuracy` |
| 最近活跃 | `teacher.students[].lastActive` |

**搜索防抖：** 输入 300ms 后自动发起 API 请求。

### 验证方式

```bash
# 班级概览：统计卡片正确 + 班级列表展示
# 学生列表：搜索框输入 → 列表过滤
# 班级下拉筛选 → 过滤出目标班级学生
# 点击学生 → 跳转到学生详情页
```

### 注意事项

- 班级概览的统计数据建议在服务端聚合（不要在 JS 中遍历计算）
- 学生列表支持搜索和筛选两个维度同时组合
- 当前全校学生数不大（几百人级别），不需要分页，一次性返回即可

---

## T.5 — 学生详情（0.5 天）

### 涉及文件

```
landing/teacher/
├── student.html                   # 新建（学生详情）
└── teacher-common.js              # 修改（如有需要）
```

### 实现要点

来自原型 `docs/06-教师端/html/student.html`：

**页面布局：**

```
[← 返回学生列表]

━━ 张三 · 个人信息 ━━
班级：高三(1)班 | 学号：20261058417 | 注册时间：2026-03-01

━━ 概览卡片 ━━
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ 总做题量  │ │ 正确率   │ │ 连续学习 │ │ 本周做题  │
│ 156 题   │ │ 72%     │ │ 5 天     │ │ 12 题    │
└──────────┘ └──────────┘ └──────────┘ └──────────┘

━━ 正确率趋势 ━━
[SVG 折线图 — 过去 30 天]

━━ 薄弱知识点 ━━
概念标签列表（按错误率降序）：
  导数 · 正确率 45%    ⚠️
  三角函数 · 正确率 52% ⚠️
  数列 · 正确率 68%    ✅
```

| 区域 | API |
|:-----|:----|
| 个人信息 | `GET /api/v1/teacher/students/{id}/` |
| 概览卡片 | 同上 |
| 正确率趋势 | 同上（`accuracyTrend` 字段） |
| 薄弱知识点 | 同上（`weakTags` 字段） |

**正确率趋势图：**

纯 SVG 折线图，无第三方图表库。实现方式：

```javascript
function renderAccuracyTrend(canvasId, data) {
  // data = [{ date: '07-11', accuracy: 75 }, { date: '07-12', accuracy: 80 }, ...]
  // SVG polyline + circle + 网格线
  // 自适应宽度，固定高度 200px
}
```

> 参考 Phase 3g 的统计页图表实现方式（纯 Canvas/SVG，无依赖）。

### 验证方式

```bash
# 从作业详情或学生列表点击一个学生 → 进入详情页
# 检查个人信息、概览卡片数据正确
# 检查折线图有数据（或空数据占位）
# 检查薄弱知识点列表按错误率排序
```

### 注意事项

- 正确率趋势数据量：取最近 30 天的每日正确率，不足 30 天按实际天数
- 薄弱知识点：从 `step_feedback` 和 `card_feedback` 聚合，按错误率降序
- 折线图用纯 SVG 实现，无第三方依赖
- 如果有 Phase 3g 的统计图表组件（SVG/CustomPaint）已在学生端实现，教师端不应该再次实现。但教师端是纯 Web 端（无 Flutter），所以需要用 Web 原生 SVG 或 Canvas 重新实现一遍。原理相同，语言换成 JavaScript

---

## T.6 — 关于页（0.15 天）

### 涉及文件

```
landing/teacher/
└── about.html                     # 新建（关于页）
```

### 实现要点

**关于页（about.html）：** 版本号（`2.0.0`）+ 更新日志 + 隐私政策/用户协议链接。

### 验证方式

```bash
# 关于页显示版本号
```

### 注意事项

（无）

---

## T.7 — 集成测试 + 部署（0.2 天）

### 集成测试

教师 Web 端是纯静态 HTML，测试方式为**手动验收测试**，不走 CI 自动化：

| 测试路径 | 步骤 | 预期结果 |
|:---------|:-----|:---------|
| 登录 | 打开 `/teacher/login.html` → 输入 teacher1/test123 | 跳转到 `/teacher/` |
| 登录失败 | 输入错误密码 | 显示错误提示，不跳转 |
| 路由守卫 | 直接访问 `/teacher/`（未登录） | 跳转到 `/teacher/login.html` |
| 作业列表 | 登录后看在主页 | 统计卡片 + 列表显示 |
| 发布作业 | 进入 publish → 选组卷+班级 → 发布 | 发布成功，列表更新 |
| 作业详情 | 点列表中的作业 | 按学生列出完成状态 |
| 班级概览 | 点「班级」导航 | 统计卡片 + 班级列表 |
| 学生列表 | 点「学生」导航 | 搜索/筛选功能可用 |
| 学生详情 | 点一个学生 | 个人信息 + 概览 + 趋势图 |
| 关于页 | 点「关于」 | 版本号正确 |

### 部署

**将原型文件从 `docs/06-教师端/html/` 复制到 `landing/teacher/`：**

```bash
# 新建目录并复制
mkdir -p landing/teacher/
cp docs/06-教师端/html/*.html landing/teacher/
cp docs/06-教师端/html/teacher-styles.css landing/teacher/
```

**nginx 配置（T.1 已配，T.7 确认即可）：**

```nginx
# /etc/nginx/sites-available/zhangyuzhixue-staging（或正式配置）
location /teacher/ {
    alias /opt/zhangyuzhixue-v2/landing/teacher/;
    index index.html;
    try_files $uri $uri/ =404;
}
```

**验证部署：**

```bash
curl -s -o /dev/null -w "%{http_code}" https://zhangyuzhixue.top/teacher/login.html
# 期望：200
curl -s -o /dev/null -w "%{http_code}" https://zhangyuzhixue.top/teacher/
# 期望：200
```

### 注意事项

- `teacher-styles.css` 从 `docs/06-教师端/html/` 复制到 `landing/teacher/`，与 HTML 文件同目录
- 不复制 `docs/06-教师端/html/styles.css`（那是学生端 UI 原型的样式，与教师端无关）
- 9 个 HTML 文件全部复制过去，但 `teacher-common.js` 是 T.1 中新建的，不属于原型文件，需手动实现

---

## 路由表

| 路径 | 页面 | 子步骤 |
|:-----|:-----|:-------|
| `/teacher/login.html` | 教师登录 | T.1 |
| `/teacher/` | 作业列表（主页） | T.2 |
| `/teacher/publish.html` | 发布作业 | T.2 |
| `/teacher/detail.html?id=` | 作业详情 | T.3 |
| `/teacher/classes.html` | 班级概览 | T.4 |
| `/teacher/students.html` | 学生列表 | T.4 |
| `/teacher/student.html?id=` | 学生详情 | T.5 |
| `/teacher/about.html` | 关于页 | T.6 |

## 测试汇总

教师端为纯静态 Web，无自动化测试框架（无 npm/无 CI）。验收方式为手动走完全部 12 条测试路径。

| 测试路径 | 数量 |
|:---------|:----:|
| 登录（成功/失败） | 2 |
| 路由守卫 | 1 |
| 作业列表（统计+列表） | 1 |
| 发布作业全流程 | 2 |
| 作业详情 | 1 |
| 班级概览 | 1 |
| 学生列表（搜索/筛选） | 2 |
| 学生详情 | 1 |
| 关于页 | 1 |
| **合计** | **~12 条手动路径** |

服务端 API 测试由 pytest 覆盖（~20 场景，见 TS.1）。

## 验收标准

1. `teacher1` 账号可登录教师 Web 端，登录后看到作业列表
2. 发布作业流程完整（选组卷→设信息→选班级→发布）
3. 作业详情按学生展示完成状态
4. 班级概览 4 个统计卡片 + 班级列表正确
5. 学生列表支持搜索和筛选
6. 学生详情展示个人信息、概览卡片、正确率趋势图、薄弱知识点
7. 关于页显示版本号
8. 8 个页面全部可通过 URL 访问
9. nginx 配置 `/teacher/` 路由后可通过域名访问
10. pytest 20 场景全部通过（TS.1 产出）

---

## 与 Flutter 端的边界

| 功能 | 在哪做 |
|:-----|:-------|
| 浏览题库 | 学生 Flutter App（教师账号登录） |
| 创建组卷 | 学生 Flutter App（paper_pick/paper_auto） |
| 阅读讲义 | 学生 Flutter App（教师身份可见全部课程） |
| 发布作业 | 教师 Web 端 |
| 查看作业完成情况 | 教师 Web 端 |
| 查看班级/学情 | 教师 Web 端 |

**教师 Web 端不需要：** Flutter SDK、pubspec、dart analyze、flutter test、assets.db、lectures.db、sync_queue。Web 端和服务端共用一个终端 session 进行 nginx 配置验证。

**与 Phase 3.5 的关系：** 教师 Web 端需在 Phase 3.5 教师 UAT 前完成。教师签收时需同时验收学生 Flutter App 和教师 Web 端的可用性。
