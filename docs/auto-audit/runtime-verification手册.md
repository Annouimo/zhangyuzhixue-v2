# 章鱼智学 · 运行时审计流程手册

> 对应 Hermes skill：`runtime-verification`
> 对应审计引擎模块：⑫（运行态审计日志验证）
> 版本：1.1 | 最后更新：2026-07-12

---

运行时审计检查的是 **app 实际跑起来之后的数据**，与静态审计（project-owner-acceptance）互补。静态审计看代码对不对，运行态审计看数据有没有。

---

## 一、一句话流程

> **你手动启动 app 走一圈 → 把命令发给 agent → agent 读日志出报告**

---

## 二、前置条件

### 测试账号（已有）

```
用户名: test_audit
密码:   test123
```

服务器和本地都已创建，含 20 条提交 + 7 天积分流水。

### 审计日志文件位置

```
Windows: %TEMP%/zhangyuzhixue_audit.ndjson
Linux:   $TMPDIR/zhangyuzhixue_audit.ndjson
```

---

## 三、完整操作流程（每一步标了谁做）

---

### Step 1 — 启动带审计的 app

**👤 你手动做：**

```bash
cd D:\Hermes\zhangyuzhixue_app_v2\flutter_app
flutter run --dart-define=AUDIT_MODE=true
```

App 启动后保持终端开着。另开一个终端做后续步骤。

**说明：** 必须带 `AUDIT_MODE=true`，否则审计日志不会写入。Release 构建不传此 flag 时零影响。

---

### Step 2 — 登录测试账号

**👤 你手动做：**

在 app 登录页输入：

```
用户名: test_audit
密码:   test123
```

登录后 app 会自动同步数据。

---

### Step 3 — 走查页面

**👤 你手动做：**

按下面的 checklist 点一遍各个页面。不用全部点完，但**点得越多查出的问题越多**。

#### 快速模式（10 个核心页，约 1-2 分钟）

| 顺序 | 页面 | 怎么进去 |
|:----:|------|---------|
| ① | **首页** | 启动即见，看一眼签到和待办 |
| ② | **推荐** | 底部第二个 Tab |
| ③ | **组卷首页** | 底部第三个 Tab，点进智能组卷看一眼再返回 |
| ④ | **作业列表** | 首页→📝 |
| ⑤ | **讲义课程** | 首页→📖，点进第一个课程看章节，再点进第一章看内容 |
| ⑥ | **个人资料** | 底部第四个 Tab |
| ⑦ | **统计** | 个人资料→📊 |
| ⑧ | **成就** | 个人资料→🏆 |
| ⑨ | **积分** | 个人资料→💰 |
| ⑩ | **关于** | 个人资料→ℹ️，看版本号 |

#### 完整模式（额外 20 页，加 2-3 分钟）

| 顺序 | 页面 | 怎么进去 |
|:----:|------|---------|
| ⑪ | 自主选题 | 组卷首页→🖐 |
| ⑫ | 发现组卷 | 组卷首页→🌐 |
| ⑬ | 收藏 | 组卷首页→🔖 |
| ⑭ | 组卷历史 | 组卷首页→📋 |
| ⑮ | 组卷预览 | 点任一组卷 |
| ⑯ | **解题** | 预览→进入，依次选/填/步/评分/地图 |
| ⑰ | 作业详情 | 作业列表→任一项 |
| ⑱ | 讲义章节/内容 | 如未在快速模式中做完 |
| ⑲ | 编辑资料 | 个人资料→编辑 |
| ⑳ | 学习偏好 | 个人资料→📋，点任一项编辑 |
| ㉑ | 等级 | 个人资料→🏅 |
| ㉒ | 做题历史 | 个人资料→📝 |
| ㉓ | 同步状态 | 个人资料→📤 |

---

### Step 4 — 让 agent 跑审计

**🤖 对 agent 说：**

> 运行运行时审计：
> ```
> python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R
> ```

**或者直接复制到聊天框：**

> ```
> /skill runtime-verification 执行 Type R — 运行时审计，项目目录"D:\Hermes\zhangyuzhixue_app_v2"
> ```

Agent 会自动：
1. 读取 `%TEMP%/zhangyuzhixue_audit.ndjson`
2. 连接本地 `server/db.sqlite3` 做预期比对
3. 运行 8 项检查，出报告

---

### Step 5 — 看报告

**👤 你手动看 + 🤖 agent 解读**

引擎输出的报告长这样：

```
══════ 章鱼智学 · 自动化审计报告 ══════

总计检查: 24 项
  CERTAIN ❌ 问题: 3
  LIKELY ⚠️  告警: 1
  SUSPICIOUS 可疑: 2
  ✅ 通过: 18

🔴 CERTAIN 问题（无需人工审核，直接采纳）
  ❌ [Server] QuestionDao: 服务端有 799 条，客户端查询返回 0 条 → assets.db 空
  ❌ [Server] pendingHomeworkCount=0，但服务端有 4 个作业 → Prefs 未缓存
  ❌ 运行时错误 2 次: SqliteException, type Null...

🔍 SUSPICIOUS 可疑（需人工确认）
  ⚠️ 等级文字可能硬编码: '🏅 Lv.5 → 升级还需 7.8'
  ⚠️ API 非 2xx 响应 1 次: /sync/qbank/version/(500)
```

**你问 agent：** "报告有什么问题？哪些需要我确认？"

Agent 会逐条解释每个 ❌ 和 ⚠️ 的含义，告诉你哪些是阻塞性的、哪些可以暂缓。

---

### Step 6 — 人工补充检查

**👤 你手动做：**

引擎查不出的东西，扫一眼：

| 检查项 | 怎么看 |
|-------|--------|
| UI 布局正不正常 | 按钮宽度、居中、间距有没有溢出 |
| 错误提示友不友好 | 出错时有没有弹出 SnackBar 而不是静默失败 |
| 空状态合不合理 | 数据为空时有没有占位符文案（不是白屏） |
| schema_version 硬编码 | 代码里写死的数字（如 `schemaVersion 2`）— 改表结构时容易忘 |

---

## 四、Skill 命令速查（复制到聊天框直接执行）

```text
/skill runtime-verification 执行 Type R — 运行时审计，项目目录"D:\Hermes\zhangyuzhixue_app_v2"
```

## 纯引擎命令行

```bash
# 运行时审计（前提：已 flutter run --dart-define=AUDIT_MODE=true 并走查过）
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R

# 全量审计（静态 + 运行时）
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2
```

## 引擎 8 项检查速览

| # | 查什么 | 级别 | 能查出什么问题 |
|---|-------|:----:|--------------|
| 1 | 你点了哪些页面 | LIKELY | 没访问的页面标记出来，不一定是问题 |
| 2 | 关键字段是否为 null | CERTAIN | gaokaoYear 为空、pendingCount 未加载 |
| 3 | 等级文字是否硬编码 | SUSPICIOUS | "Lv.5" 写死在代码里 |
| 4 | 跨页数据是否一致 | SUSPICIOUS | 首页待办数 ≠ 作业页待办数 |
| 5 | DAO 是否查出 0 行 | CERTAIN | assets.db 空表：查什么都返回 0 |
| 6 | **服务端 vs 客户端数据对比** | CERTAIN | 服务端 799 题 vs 客户端 0 题 → ❌ |
| 7 | **运行时有没有抛异常** | CERTAIN | catch 块捕获的错误、全局错误 |
| 8 | **API 有没有返回 4xx/5xx** | SUSPICIOUS | 哪个端点报错、报了多少次 |

---

## 五、常见问题

### Q: agent 说"未找到审计日志文件"

**原因：** 没带 `AUDIT_MODE` 启动 app。

**你手动做：**
```bash
flutter run --dart-define=AUDIT_MODE=true
```

### Q: 报告说"未访问页面 8 个"

正常。你只点了快速模式的 10 页，剩下 20 页没点。引擎如实记录——不影响已查出问题的准确性。下次想查更多就点多一些页面。

### Q: 报告说"服务端 DB 不存在"

**原因：** 本地 `server/db.sqlite3` 不存在或不在预期位置。

**解决：** 问 agent "服务端 DB 怎么同步？"

### Q: 报告说有 API 500 错误

可能是服务器代码没部署最新版本。问 agent："这些 API 错误是什么原因？"

### Q: 我该怎么问 agent 问题？

直接说人话，比如：

- "报告有什么问题？"
- "哪些需要我手动确认？"
- "这个问题严重吗？"
- "assets.db 怎么修复？"
