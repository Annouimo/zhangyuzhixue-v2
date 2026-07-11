# 章鱼智学 · 运行时审计流程手册

> 对应 Hermes skill：`runtime-verification`
> 对应审计引擎模块：⑫（运行态审计日志验证）
> 版本：1.0 | 最后更新：2026-07-12

---

## 一、什么是运行时审计

**运行时审计**检查的是"app 跑起来之后实际看到的数据"，与**静态审计**（project-owner-acceptance）互补：

| 维度 | 静态审计 | 运行时审计 |
|------|---------|-----------|
| 检查对象 | 代码文件 + 设计文档 | 运行中的 app + 实际 DB |
| 依赖 | 纯 Python，< 30 秒 | 需 `flutter run` + 人工走查 |
| 查出问题类型 | 结构缺失、字段不匹配、stub | 数据为空、类型崩溃、静默错误、服务端不一致 |
| 执行顺序 | 先跑 | 后跑（代码审计通过后） |
| 频率 | 每次代码变更 | 每个功能/数据变更周期一次 |

### 运行时审计能查出什么

| 问题类 | 示例 | 查出方式 |
|-------|------|---------|
| **捆绑 DB 数据为空** | assets.db 中 questions 表 0 行 | 模块 ⑪（静态）或 模块 ⑫ §6 服务端预期核对 |
| **服务端 vs 客户端数据不一致** | 服务端有 4 个作业，首页待办数为 0 | 模块 ⑫ §6 — 自动 SQL 查询 vs 审计日志比对 |
| **运行时类型崩溃** | `gaokao_year: remote['gaokao_year'] as String?` 对 int 抛 TypeError | 模块 ⑫ §7 — 错误日志捕获 |
| **静默 try/catch 吞错误** | catch 块只 `debugPrint` 不展示给用户 | 模块 ⑫ §7 — 60+ catch 块注入 AuditLogger.error |
| **API 静默失败** | 4xx/5xx 响应被 Dio 拦截器吞掉 | 模块 ⑫ §8 — API 错误审查 |
| **跨层算法分歧** | 服务端对 .gz 做 hash，客户端对 .db 做 hash | 模块 ⑩ 标记 + 模块 ⑫ 日志验证 |
| **DB 迁移失败** | 用户 DB schema 版本不匹配，`no such table` 崩溃 | 模块 ⑫ §7 — 错误日志捕获 |
| **全局错误逃逸** | Flutter 框架级错误、PlatformDispatcher 错误 | main.dart `FlutterError.onError` 钩子 |
| **页面数据硬编码** | 等级文字写死 "Lv.5 → 升级还需 7.8" | 模块 ⑫ §3 — levelText 模式匹配 |

---

## 二、前置条件

### 2.1 测试账号

已在服务器（ECS）和本地创建测试账号 `test_audit`，含：

- 20 条提交记录
- 7 天积分流水
- 已绑定班级

```
用户名: test_audit
密码:   test123
```

### 2.2 审计日志基础设施

运行时审计依赖 Flutter 端的 `AuditLogger` 类，其为每个页面/DAO/Prefs/Sync 操作在运行时输出结构化 NDJSON 日志。

启动方式：

```bash
# 必须带 AUDIT_MODE flag
flutter run --dart-define=AUDIT_MODE=true
```

不传 `AUDIT_MODE` 时，`bool.fromEnvironment('AUDIT_MODE')` 为 false，Dart tree-shaking 消除全部 `AuditLogger` 调用，Release 构建零开销。

### 2.3 审计日志写入位置

```
Windows: %TEMP%/zhangyuzhixue_audit.ndjson
macOS/Linux: $TMPDIR/zhangyuzhixue_audit.ndjson
```

格式为 **NDJSON**（每行一个 JSON 对象），引擎逐行读取。

---

## 三、完整工作流

### Step R1 — 启动

```bash
# 确保工作区干净
cd D:\Hermes\zhangyuzhixue_app_v2
git stash

# 启动带审计模式的 Flutter app
flutter run --dart-define=AUDIT_MODE=true
```

App 启动时会自动：
1. 在 `%TEMP%/zhangyuzhixue_audit.ndjson` 创建新日志文件（覆盖旧文件）
2. 注册 `FlutterError.onError` 和 `PlatformDispatcher.onError` 全局错误钩子
3. 注册 Dio 错误拦截器

**注意：** `flutter run` 需要在终端前台保持。另开一个终端执行后续步骤。

### Step R2 — 登录测试账号

在 app 的登录页输入：

```
用户名: test_audit
密码:   test123
```

登录后 app 会自动同步用户数据（提交记录、积分等）。

### Step R3 — 走查页面

按以下 checklist 手动点击每个页面。引擎会报告未访问页面，所以没必要每次都点完，但**覆盖越多、发现的问题越多**。

#### 必须覆盖的页面

| # | 页面 | 入口 | 预期内容 | 关键检查点 |
|---|------|------|---------|-----------|
| 1 | **首页** | 启动即见 | 签到天数、待办作业数 | pendingCount 应为 4（服务端有 4 个作业） |
| 2 | **推荐** | 底部 Tab 2 | 预设数 >= 1 | presetCount |
| 3 | **组卷首页** | 底部 Tab 3 | 入口卡片可见 | visited=true |
| 4 | 智能组卷 | 组卷首页→🤖 | 题目列表 | count |
| 5 | 自主选题 | 组卷首页→🖐 | 筛选面板+题目 | totalCount |
| 6 | 发现组卷 | 组卷首页→🌐 | 组卷列表 | totalPapers |
| 7 | 收藏 | 组卷首页→🔖 | 收藏列表 | total |
| 8 | 组卷历史 | 组卷首页→📋 | 历史列表 | total |
| 9 | 组卷预览 | 任一组卷进入 | 题数、难度 | hasPreview |
| 10 | **解题**（选择） | 从预览进入 | 题号、选项 | qid, optionsCount |
| 11 | **解题**（填空） | 从解题进入 | 题号 | qid, submitted |
| 12 | **解题**（步骤） | 从解题进入 | 步骤数 | stepCount |
| 13 | **解题**（评分） | 解答完成后 | 评分内容 | difficulty, calcScore |
| 14 | **解题地图** | 解答题中 | 进度、星数 | progress, stars |
| 15 | **作业列表** | 首页→📝 | 作业数 | total >= 1, pending |
| 16 | 作业详情 | 任一项进入 | 题目列表 | qCount |
| 17 | **讲义课程** | 首页→📖 | 课程数 | courseCount |
| 18 | 讲义章节 | 课程进入 | 章节数 | chapterCount |
| 19 | 讲义内容 | 章节进入 | 内容存在 | hasContent |
| 20 | **个人资料** | 底部 Tab 4 | 姓名、高考年份 | name, gaokaoYear |
| 21 | 编辑资料 | 个人资料→编辑 | 字段加载 | name, gaokaoYear, saving |
| 22 | 学习偏好列表 | 个人资料→📋 | 预设数 | presetCount |
| 23 | 学习偏好编辑 | 列表中任一项 | 筛选结果 | qCount |
| 24 | 统计 | 个人资料→📊 | 4 概览项 | hasData |
| 25 | **成就** | 个人资料→🏆 | 成就列表 | total, unlocked |
| 26 | 等级 | 个人资料→🏅 | 等级、经验 | level, xp |
| 27 | **积分** | 个人资料→💰 | 积分余额 | balance, today |
| 28 | 做题历史 | 个人资料→📝 | 历史条数 | total |
| 29 | 同步状态 | 个人资料→📤 | 队列长度 | pending, failed |
| 30 | 关于 | 个人资料→ℹ️ | 版本号 | version |

#### 预估耗时

- 最小覆盖（标 * 的 10 页）：约 1-2 分钟
- 全量覆盖（30 页）：约 3-5 分钟

### Step R4 — 捕获

走查完成后，在另一个终端运行审计引擎：

```bash
# 确认审计日志已生成
dir %TEMP%\zhangyuzhixue_audit.ndjson

# 运行 Type R 审计
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R
```

引擎自动做 8 项检查：

| # | 检查项 | 级别 | 能查出 |
|---|-------|:----:|--------|
| 1 | 页面覆盖 | LIKELY | 哪些页面被访问、哪些缺失 |
| 2 | 非空断言 | CERTAIN | 关键字段为 null（如 gaokaoYear） |
| 3 | 硬编码检测 | SUSPICIOUS | levelText 含 "Lv.X" 数字模式 |
| 4 | 跨页一致性 | SUSPICIOUS | pendingCount 在首页和作业页不一致 |
| 5 | DAO 0 行检测 | CERTAIN | assets.db 空表查不出数据 |
| 6 | **服务端预期核对** | CERTAIN | 服务端 799 题 vs 客户端 0 行 |
| 7 | 运行时错误审查 | CERTAIN | catch 块捕获的异常、全局错误 |
| 8 | API 错误审查 | SUSPICIOUS | 非 2xx 响应端点及次数 |

### Step R5 — 阅读报告

引擎输出示例：

```
══════ 章鱼智学 · 自动化审计报告 ══════

总计检查: 24 项
  CERTAIN ❌ 问题: 3
  LIKELY ⚠️  告警: 1
  SUSPICIOUS 可疑: 2
  ✅ 通过: 18

🔴 CERTAIN 问题（无需人工审核）
  ❌ ❌ [Server] QuestionDao: 服务端有 799 条，客户端查询返回 0 条
  ❌ ❌ [Server] pendingHomeworkCount=0，但服务端有 4 个作业
  ❌ ❌ 运行时错误 2 次 (2 个源): [DatabaseProvider] SQL logic error; [IndexPage] type 'Null' is not a subtype of type 'int'

🔍 SUSPICIOUS 可疑（需人工审核 3 分钟/条）
  ⚠️ 等级文字可能硬编码: '🏅 Lv.5 → 升级还需 7.8'
  ⚠️ API 非 2xx 响应 1 次 (1 个端点): /sync/qbank/version/(500)
```

### Step R6 — 人工补充检查

引擎无法覆盖的部分：

| 检查项 | 方法 |
|-------|------|
| UI 布局是否正常 | 肉眼观察按钮宽度、居中、间距 |
| 动画/过渡是否流畅 | 操作各页面切换 |
| 错误提示是否友好 | 观察 catch 错误后是否有 SnackBar/ErrorPlaceholder |
| 空状态是否合理 | 查看数据为空页面的占位符文案 |
| schema_version 硬编码 | 检查 Drift `onUpgrade` 代码 |

---

## 四、审计日志文件格式

### 4.1 NDJSON 行结构

```json
{"seq":1, "ts":"2026-07-12T10:00:00.000", "cat":"page", "src":"IndexPage", "key":"pendingCount", "val":"4", "vt":"int"}
```

| 字段 | 含义 |
|------|------|
| `seq` | 序号（从 1 递增） |
| `ts` | ISO 8601 时间戳 |
| `cat` | 类别：`page` `dao` `prefs` `sync` `api` `error` `_meta` |
| `src` | 来源：页面名、DAO 方法名、端点名 |
| `key` | 字段名 |
| `val` | 值（字符串化） |
| `vt` | 值类型：`int` `str` `bool` `double` `null` |

### 4.2 各类别示例

**页面层（page）：**
```json
{"cat":"page", "src":"IndexPage", "key":"pendingCount", "val":"4"}
{"cat":"page", "src":"IndexPage", "key":"streakDays", "val":"7"}
{"cat":"page", "src":"ProfilePage", "key":"name", "val":"审计测试"}
```

**DAO 层（dao）：**
```json
{"cat":"dao", "src":"QuestionDao.search", "key":"rowCount", "val":"0"}
{"cat":"dao", "src":"UserDao.getInfo", "key":"rowCount", "val":"1"}
```

**Prefs 层（prefs）：**
```json
{"cat":"prefs", "src":"AppPrefs", "key":"app_pending_homework_count", "val":""}
{"cat":"prefs", "src":"AppPrefs", "key":"app_auth_token", "val":"eyJ..."}
```

**同步层（sync）：**
```json
{"cat":"sync", "src":"syncAll", "key":"data", "val":"{\"pushCount\":3}"}
{"cat":"sync", "src":"checksum", "key":"data", "val":"{\"type\":\"qbank\",\"match\":true}"}
```

**错误层（error）：**
```json
{"cat":"error", "src":"DatabaseProvider._init", "key":"message", "val":"SqliteException: no such table: user_profile"}
{"cat":"error", "src":"FlutterError", "key":"message", "val":"type 'Null' is not a subtype of type 'int'"}
```

**API 响应（api）：**
```json
{"cat":"api", "src":"/sync/qbank/version/", "key":"statusCode", "val":"500"}
{"cat":"api", "src":"/auth/login/", "key":"statusCode", "val":"200"}
```

---

## 五、常见问题排查

### 5.1 审计日志文件未生成

```
⚠️ 未找到运行时审计日志文件
```

**原因：** 未带 `AUDIT_MODE` flag 启动，或 app 未运行过。

**解决：**
```bash
flutter run --dart-define=AUDIT_MODE=true
```

### 5.2 页面覆盖不全

```
⚠️ 未访问页面 (8 个): LectureChaptersPage, SolveChoicePage...
```

**原因：** 走查时没点到某些页面。这不一定是问题——引擎如实报告哪些页面没被覆盖。如果这些页面确实没有数据需求，可以忽略。

### 5.3 服务端 DB 不存在

```
⚠️ 未找到服务端 DB — 跳过服务端预期核对
```

**原因：** 本地 `server/db.sqlite3` 不存在。引擎使用本地服务器 DB 做预期比对。

**解决：** 确保本地开发环境有 DB（从服务器下载或本地生成）。

### 5.4 大量 API 500 错误

```
⚠️ API 非 2xx 响应 5 次 (2 个端点): /sync/qbank/version/(500,500), /sync/lecture/version/(500)
```

**原因：** 服务端版本检查接口返回 500。可能是部署的代码与本地 DB 结构不一致。

**处理：** 检查服务器端 `migrate` 状态和 nginx/gunicorn 日志。

### 5.5 运行时错误影响页面加载

```
❌ 运行时错误 3 次: [IndexPage] type 'Null' is not a subtype of type 'int'
```

**原因：** DAO 返回 null 字段，页面强转 int 崩溃。常见于 assets.db 空表。

**处理：** 运行 `--type A` 或 `--type B` 检查 assets.db 数据完整性。

---

## 六、与静态审计的配合使用

### 推荐执行顺序

```
1. git commit（确保代码最新）
2. python audit_engine.py . --type A   # 后端静态审计（含 DB 内容）
3. python audit_engine.py . --type C   # UI 静态审计
4. flutter run --dart-define=AUDIT_MODE=true  # 启动 app
5. 登录 test_audit + 走查页面
6. python audit_engine.py . --type R   # 运行时审计
```

### 合并审计运行

```bash
# 全量静态 + 运行时
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2
```

---

## 七、审计命令速查

```bash
# ── 运行态审计（先 flutter run --dart-define=AUDIT_MODE=true）──
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R

# ── 全量审计（静态 + 运行时，但需要审计日志存在）──
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2

# ── 启动带审计日志的 app ──
cd D:\Hermes\zhangyuzhixue_app_v2\flutter_app
flutter run --dart-define=AUDIT_MODE=true

# ── 查看审计日志原始内容 ──
type %TEMP%\zhangyuzhixue_audit.ndjson

# ── 清理旧日志（每次 flutter run 自动覆盖）──
del %TEMP%\zhangyuzhixue_audit.ndjson
```
