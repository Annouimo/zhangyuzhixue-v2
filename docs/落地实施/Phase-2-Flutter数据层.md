# Phase 2 — Flutter 数据层（4.5 天，每步测）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 2 的细化执行方案总入口。
> 各子步骤的详细方案见对应的拆分文档。
> 状态：**已完成** | 最后更新：2026-07-11

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 | 细化文档 |
|--------|------|------|------|---------|
| **2.1** 🔧CI | 3 个 Drift Database（assets/lectures/user）+ 11 个 DAO | 1.5 天 | ✅ | [Phase-2.1-DB+DAO.md](./Phase-2.1-DB+DAO.md) |
| **2.2** | DatabaseProvider（生命周期）+ ApiClient（3 拦截器） | 0.5 天 | ✅ | [Phase-2.2-2.3-ApiClient+Prefs.md](./Phase-2.2-2.3-ApiClient+Prefs.md) |
| **2.3** | AppPrefs + ConnectivityMonitor | 0.5 天 | ✅ | ↑ 同上 |
| **2.4** | 13 个 Repository 全部实现 | 1.5 天 | ✅ | [Phase-2.4-Repository.md](./Phase-2.4-Repository.md) |
|| **2.5** | 同步引擎 + 更新机制 | 1 天 | ✅ | [Phase-2.5-SyncEngine.md](./Phase-2.5-SyncEngine.md) |

### 前置条件

- [x] 服务端已部署到 staging（Phase 1.5），API 端点可用
- [x] Flutter SDK（3.44+）和 Drift 环境就绪
- [x] 已读取 `docs/02-数据/数据库结构设计.md` 全部表定义
- [x] 已读取 `docs/05-Flutter/` 下所有 Repository 设计稿（13 个文件）

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) | 所有表定义（assets + user） |
| [`Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | 目录结构、Repository 规范、Widget 复用 |
| [`数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | DAO→Database、Repository→DAO 层间契约 |
| [`同步引擎设计.md`](../05-Flutter/同步引擎设计.md) | 同步队列状态机 + 重试策略 |
| [`docs/05-Flutter/Repository/*.dart`](../05-Flutter/Repository/) | 13 个 Repository 接口 + 数据模型定义 |
| [`docs/05-Flutter/sync/*.dart`](../05-Flutter/sync/) | 同步引擎 4 个 Dart 设计稿 |
| [`更新机制.md`](../02-数据/更新机制.md) | 版本号体系与启动流程 |
| [`构建脚本设计.md`](../02-数据/构建脚本设计.md) | assets.db/lectures.db 表结构定义 |
| [`本地数据架构.md`](../02-数据/本地数据架构.md) | 三库方案和网络失败处理 |

### 当前 Flutter 端状态（Phase 2 2.1~2.4 完成后）

```
flutter_app/lib/
├── main.dart              # 仅骨架
├── pubspec.yaml           # ✅ 依赖已定义
├── lib/data/
│   ├── api/               # ✅ ApiClient（3 拦截器）+ AuthApi/SyncApi/UserApi
│   ├── daos/              # ✅ 11 个 DAO（memory DB CRUD，88 条测试）
│   ├── database/          # ✅ 3 个 Drift Database + DatabaseProvider
│   ├── helpers/           # ✅ 工具方法（PDF 下载、题目状态推算）
│   ├── network/           # ✅ ConnectivityMonitor
│   ├── prefs/             # ✅ AppPrefs
│   └── sync/              # ⚠️ 骨架就位（Phase 2.5 待完成）
├── lib/domain/            # ✅ 13 个 Repository（57 条集成测试）
└── test/
    ├── data/api/          # ✅ 拦截器链 + API mock 测试
    ├── data/daos/         # ✅ 11 个 DAO 测试文件
    ├── data/database/     # ✅ DatabaseProvider 测试
    ├── data/domain/       # ✅ 13 个 Repository 测试
    ├── data/helpers/      # ✅ Helper 单元测试
    ├── data/network/      # ✅ ConnectivityMonitor 测试
    ├── data/prefs/        # ✅ AppPrefs 测试
    └── data/sync/         # ⚠️ 4 个测试失败（update_manager 未实现）
```

### 🔧CI 更新说明

| 子步骤 | CI 变更 |
|--------|---------|
| **2.1** | CI 中 Flutter job 的 `flutter test` 开始包含 DAO 测试。配置已就位无需改动 |
| **2.2–2.5** | CI 无变更，增量测试已在 `flutter test` 中覆盖 |

> 详细实现方案：
> - [Phase-2.1-DB+DAO.md](./Phase-2.1-DB+DAO.md) — 3 个 Database + 11 个 DAO
> - [Phase-2.2-2.3-ApiClient+Prefs.md](./Phase-2.2-2.3-ApiClient+Prefs.md) — DatabaseProvider + ApiClient + Prefs + ConnectivityMonitor
> - [Phase-2.4-Repository.md](./Phase-2.4-Repository.md) — 13 个 Repository
> - [Phase-2.5-SyncEngine.md](./Phase-2.5-SyncEngine.md) — 同步引擎 + 更新机制

---

## 依赖关系说明

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

## 测试汇总

| 层级 | 测试项 | 测试数 |
|------|-------|-------|
| L1: DAO 单元测试 | 11 个 DAO × memory DB | ~59 |
| L2: 基础设施 | DatabaseProvider + ApiClient 拦截器 + AppPrefs + Connectivity | ~19 |
| L3: 基础设施 | AppPrefs + ConnectivityMonitor | ~8 |
| L4: Repository 集成 | 13 个 Repository + 5 个尾部算法类 | ~75 |
| L5: 同步引擎 | SyncPusher + SyncManager + UpdateManager | ~28 |
| **合计** | | **~189 个测试** |

> 测试嵌入到每个子步骤中，做到哪步测到哪步，不攒到最后。

---

## 验收标准

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
