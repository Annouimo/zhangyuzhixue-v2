# Phase 5 — 集成测试（1 天）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 5 的细化执行方案。
> 状态：**待开始** | 最后更新：2026-07-11

---

## 总览

| 层 | 内容 | 工时 | 执行方式 | 状态 |
|:---|:-----|:-----|:---------|:----:|
| **L6** | 服务端 API 契约（pytest + DRF APIClient） | 0.5 天 | CI（每次 push 自动跑） | ⬜ |
| **L7** | E2E（Flutter integration_test，4 条路径） | 0.3 天 | 本地手动跑（不跑 CI） | ⬜ |
| **L8** | 构建验证（.db.gz checksum） | 0.2 天 | CI + 本地 | ⬜ |
| | **合计** | **~1 天** | | |

### 前置条件

- [ ] Phase 3 UI 全部完成并验收通过
- [ ] Phase 4 辅助系统全部完成并验收通过
- [ ] `flutter test` 和 `pytest` 当前全绿（Phase 2/3/4 积累的测试无回归）
- [ ] Staging 环境运行中，API 端点可用

### 关键设计文档索引

| 文档 | 用途 |
|:-----|:------|
| [`API设计.md`](../03-服务端/API设计.md) | 全部端点定义，用于 L6 测试用例边界判定 |
| [`00-落地计划.md`](../00-落地计划.md) §Phase 5 | 集成测试顶层设计 |
| [`测试策略.md`](../测试策略.md) | 8 层测试金字塔定义 |

---

## L6 — 服务端 API 契约全覆盖（0.5 天）

### 现状分析

当前服务端测试覆盖（全 89 条通过）：

| 测试文件 | 条数 | 覆盖内容 |
|:---------|:----:|:---------|
| `accounts/tests/test_auth.py` | 13 | login/register/refresh/logout |
| `accounts/tests/test_user.py` | 7 | user-me/avatar/level-percentile |
| `courses/tests/test_lecture.py` | 5 | courses/chapters/content |
| `interactions/tests/test_sync.py` | 12 | version check ×2 + sync push + batch |
| `interactions/tests/test_pdf.py` | 12 | PDF request-token + pdf/view + 签名 |
| `system/tests/test_version.py` | 3 | DbVersion 查询 |
| `system/tests/test_auditlog.py` | 7 | auditlog 写入 |
| `scripts/tests/test_build_*.py` | 27 | 构建工具函数 + schema 一致性 |
| **合计** | **89** | |

### 所需补充

依据 `API设计.md` 和实际路由表，目前缺少以下端点测试：

| 端点 | 路径 | 当前状态 | 建议最少测试数 |
|:-----|:-----|:---------|:------------:|
| 用户更新 | `PATCH /api/v1/user/me/` | test_user.py 已有但覆盖不足（仅测 GET） | +2（更新成功 + 非法字段） |
| 头像上传 | `POST /api/v1/user/avatar/` | test_user.py 有基本测试 | +1（过大文件拒绝） |
| 讲义 | `GET /api/v1/lectures/chapters/{id}/content/` | test_lecture.py 5 条覆盖基本路径 | +2（章节不存在 → 404、空内容） |
| 管理工具 | `GET /admin/system/tools/` | 无测试 | +1（页面可访问、按钮存在） |
| API 文档 | `GET /api/docs/` | 无测试 | +1（返回 200、schema 格式正确） |
| 认证登录 | `POST /api/v1/auth/login/` | test_auth.py 13 条基本够 | 确认即可 |
| 同步推送 | `POST /api/v1/sync/push/` | test_sync.py 12 条基本够 | +2（空 batch、非法 entity_type） |

**补充测试合计：~9 条**

### 涉及文件

```
server/accounts/tests/test_user.py     # 修改：补充 PATCH 更新 + 头像超过 2MB 拒绝
server/courses/tests/test_lecture.py   # 修改：补充章节不存在 + 空内容
server/system/tests/test_version.py    # 修改（或新建 test_docs.py）：API 文档 schema
server/system/tests/test_tools.py      # 新建：Admin tools 页面可访问
```

### 实现要点

**PATCH /api/v1/user/me/ 测试新增（test_user.py）：**

```python
def test_update_profile_success(self):
    """修改 real_name/phone/gaokao_year 成功"""
    response = self.client.patch('/api/v1/user/me/', {
        'real_name': '新名字', 'phone': '13900001111', 'gaokao_year': 2027
    }, format='json')
    assert response.data['code'] == 0
    assert response.data['data']['real_name'] == '新名字'

def test_update_profile_invalid_field(self):
    """修改 username/role 等不可修改字段 → 静默忽略或 40201"""
    response = self.client.patch('/api/v1/user/me/', {
        'username': 'hacker', 'role': 'teacher'
    }, format='json')
    assert response.data['code'] == 0  # 不报错，但字段不变
```

**头像超过 2MB 拒绝（test_user.py）：**

```python
def test_avatar_too_large(self):
    """超过 2MB 的图片上传返回 400"""
    large_file = io.BytesIO(b'x' * (2 * 1024 * 1024 + 1))
    large_file.name = 'large.png'
    response = self.client.post('/api/v1/user/avatar/',
                                {'avatar': large_file}, format='multipart')
    assert response.data['code'] != 0  # 应返回业务错误码
```

**测试组织建议：**

当前测试分布在各 App 目录的 `tests/` 下。L6 不改结构——只在现有测试文件中追加缺失用例。**不拆不合并。**

### 验证方式

```bash
cd server
pytest accounts/ courses/ interactions/ system/ -v --tb=short
# 期望：98+ passed（原 89 + 新增 ~9）
```

### CI 更新

CI 配置已在 Phase 1.3 中写入 pytest 命令，**无需改动**。新增的测试文件会自动被 pytest 发现。

---

## L7 — E2E 测试（0.3 天）

### 设计决策

**不在 CI 中运行**，原因：

| 因素 | 本地 E2E | CI E2E |
|:-----|:---------|:--------|
| 运行时间 | ~5–10 分钟 | ~15+ 分钟（含模拟器启动 + APK build） |
| 稳定性 | 可控（失败的通常是真 bug） | flaky（模拟器渲染延迟、动画 timing） |
| 基础设施 | 开发机已有 Flutter SDK + 模拟器 | GitHub Actions 需 AVD setup（额外 50 行 yaml） |
| 收益 | 兜底核心路径 | 与本地跑结果一样，但多花 3 倍 setup 时间 |

**决策结论：** E2E 脚本写好，合并 master / 发版前在本地跑一遍。

### 涉及文件

```
flutter_app/test_driver/
└── integration_test.dart              # 新建：integration_test 入口（flutter_driver 模式）

flutter_app/integration_test/
├── e2e_auth_test.dart                 # 新建：注册 → 登录 → 登出
├── e2e_solve_test.dart                # 新建：选填 + 解答 完整流程
├── e2e_exam_test.dart                 # 新建：组卷（筛选→确认→预览）
└── e2e_sync_test.dart                 # 新建：提交数据 → 同步推送 → 服务端验证

scripts/run_e2e.bat                    # 新建：一键运行脚本
scripts/run_e2e.sh                     # 新建（跨平台参考）
```

### 4 条路径详细设计

#### 路径 1：注册 → 登录（e2e_auth_test.dart）

```
1. 打开 App → 看到登录页
2. 点击「去注册」
3. 输入有效邀请码 → 填写用户名/密码/姓名 → 提交
4. 验证提示「注册成功，请登录」
5. 用刚注册的账号登录
6. 验证跳转到 MainShell（底部 4 Tab 可见）
7. 登出 → 回到登录页
```

**关键断言：**
- 注册成功后当前页是登录页（不是 MainShell）
- 登录成功后底部导航 Tab 全部可见

#### 路径 2：解题流程（e2e_solve_test.dart）

```
1. 登录后 → 从作业或组卷进入一道选择题
2. 等待冷却倒计时结束 → 选一个选项 → 点击提交
3. 验证结果区显示正确/错误 + 解析（MdLatexBody 已渲染）
4. 看到完成横幅 🎉 和「下一题」「⭐ 评分」
5. 点击「⭐ 评分」→ 进入评分页
6. 给 3 个维度各打 5 星 → 提交
7. 返回 → 重新进入同一题 → 验证复访模式（跳过冷却，直接展示结果）
8. （可选）做一道解答题 → 验证步骤卡展开 + 反馈按钮
```

**关键断言：**
- 提交后答案区域可见（非空）
- 评分页 3 组星级 UI 可交互
- 复访时无冷却倒计时

#### 路径 3：组卷流程（e2e_exam_test.dart）

```
1. 登录 → 进入组卷页
2. 智能组卷：筛选（年份/区/难度）→ 确认组卷
3. 验证跳转到预览页，题目列表非空
4. 返回 → 进入自主选题
5. 勾选 3 道题 → 确认 → 验证预览页题目数为 3
6. 进入「我的组卷」→ 刚创建的试卷在列表中
```

**关键断言：**
- 预览页题目列表长度 > 0
- 「我的组卷」列表中包含刚创建的试卷

#### 路径 4：同步推送（e2e_sync_test.dart）

```
1. 模拟器关闭网络 → 做一道选择题并提交
2. 验证数据写入 user.db（submission_detail 表有记录）
3. 打开同步队列页面 → 验证队列中有待推送项
4. 恢复网络 → 调用 SyncManager.pushNow()
5. 验证服务端对应表（StudentSubmission + SubmissionDetail）有相同数据
```

**关键断言：**
- 离线时数据存本地，不丢失
- 联网后同步成功，服务端记录存在

### 项目结构说明

Flutter integration_test 的标准目录结构：

```
flutter_app/
├── integration_test/          ← 测试文件放这里
│   ├── e2e_auth_test.dart
│   ├── e2e_solve_test.dart
│   ├── e2e_exam_test.dart
│   └── e2e_sync_test.dart
└── test_driver/
    └── integration_test.dart  ← 驱动入口
```

`test_driver/integration_test.dart` 内容（标准模板）：

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

**依赖：** `pubspec.yaml` 需加 `integration_test` 和 `flutter_test`（在 dev_dependencies 中）。

### 运行方式

```bash
# Windows（用脚本）
scripts/run_e2e.bat

# 或直接命令行
cd flutter_app
flutter test integration_test/ -v

# 指定单条路径
flutter test integration_test/e2e_auth_test.dart -v
```

### 验证方式

```bash
flutter test integration_test/ -v
# 期望：4 条路径全部通过（~5–10 分钟）
```

### 注意事项

- E2E 测试依赖 **真机或模拟器**，需要预装 Flutter App。不能在本机无 GUI 环境（如 SSH）下运行
- 测试中**不要依赖 staging 环境在线**（解题/组卷验证用本地 DB 数据，同步路径才依赖网络）
- 路径 4（同步推送）需要 staging 环境可访问。如果 staging 不可用，该路径可单独跳过
- 每条路径起始都用 `setUp` 登录一次（或复用 token），避免重复输入
- 异步操作（冷却 + 动画）用 `await tester.pump()` + 适当延迟等待，不盲目 `pumpAndSettle`
- E2E 发现的 bug 修复后，先在 L1-L4 加对应单元/Widget 测试，确认不依赖 E2E 来守回归

---

## L8 — 构建验证（0.2 天）

### 涉及文件

```
server/scripts/build_assets.py          # 确认（不改）
server/scripts/build_lectures.py        # 确认（不改）
server/scripts/tests/test_schema_consistency.py  # 已有，确认即可
server/scripts/tests/test_build_schemas.py       # 已有 14 条，确认即可
```

### 实现要点

L8 包含两个层面的验证：

**1. 构建产物完整性（脚本已实现——确认即可）：**

当前已有 `test_build_schemas.py`（14 条）和 `test_schema_consistency.py`（3 条），覆盖：
- 构建后 .db.gz 可解压、SQLite 可读
- 表结构与 Drift 定义一致（列名、类型）
- checksum 写入 DbVersion 表

**2. 构建脚本幂等性测试（补充）：**

```python
def test_build_idempotent(tmp_path):
    """两次连续运行构建脚本，产物 checksum 一致"""
    # 第一次构建
    run_build(tmp_path)
    hash1 = sha256(tmp_path / 'qbank_v1.db.gz')
    # 第二次构建（不修改数据）
    run_build(tmp_path)
    hash2 = sha256(tmp_path / 'qbank_v1.db.gz')
    assert hash1 == hash2  # 数据不变时，产物不变
```

**3. CI 中验证构建（脚本确认即可）：**

CI 当前未配置构建验证。Phase 5 也不在 CI 中增加构建步骤（构建只在新数据入库时才需要跑，不随每次 push 触发）。

### 验证方式

```bash
cd server
pytest scripts/tests/ -v --tb=short
# 期望：27+ passed（原 27 + 新增幂等性测试）
```

### 注意事项

- 构建产物（`.db.gz`）不提交到 git，只在 staging 和正式环境运行时生成
- CI 中不需要构建步骤——L6 测试依赖的是 Django models，不是 Drift 表结构
- 构建脚本的幂等性只在首次跑和迁移数据后关注，日常开发确认 `test_schema_consistency.py` 通过即可

---

## 测试汇总

| 层 | 类型 | 新增 | 运行位置 | 运行时机 |
|:---|:-----|:----:|:---------|:---------|
| L6 | 服务端 pytest | ~9 条 | CI（GitHub Actions） | 每次 push |
| L7 | Flutter E2E | ~4 条 | 本地 | 合并 master / 发版前 |
| L8 | 构建 pytest | ~3 条 | CI | 每次 push（已有脚本自动覆盖） |
| | **合计** | **~16 条** | | |

---

## 验收标准

1. `cd server && pytest accounts/ courses/ interactions/ system/ -v` — **98+ passed**
2. 所有 API 端点至少有一条成功的请求-响应测试
3. 4 条 E2E 脚本文件就位，在本地模拟器上跑通
4. `scripts/run_e2e.bat` 可用
5. 构建脚本幂等性验证通过
6. L6 和 L8 在 CI 上自动运行（E2E 除外）
