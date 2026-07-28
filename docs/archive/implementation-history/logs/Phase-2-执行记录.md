# Phase 2 — 执行记录

> 执行期间：2026-07-10 ~ 2026-07-11 | 对应计划文档：Phase-2-Flutter数据层.md（含子步骤拆分文档）

---

## 2.1 — 3 个 Drift Database + 11 个 DAO

**提交：** `5ed85c1`（实现） + `3962950`（测试）

- [x] assets_database.dart（12 表 + _meta）
- [x] lectures_database.dart（6 表 + _meta）
- [x] app_database.dart（15 表）
- [x] 11 个 DAO（构造注入，memory DB 可编译）
- [x] DAO 测试 88 用例全部通过

## 2.2 — DatabaseProvider + ApiClient

**提交：** `8dd7066`

- [x] DatabaseProvider（三库生命周期 + replace/clear）
- [x] ApiClient（Dio 单例 + 3 拦截器）
- [x] auth_api / sync_api / user_api
- [x] 拦截器链 + API mock 测试 12 用例全部通过

## 2.3 — AppPrefs + ConnectivityMonitor

**提交：** `11a8749`

- [x] AppPrefs（token/version/userCache/ratingCooldown 等全局 key）
- [x] ConnectivityMonitor（BehaviorSubject 流式状态）
- [x] 测试 16 用例全部通过（含 ratingCooldown 补全 `2058ba5`）

## 2.4 — 13 个 Repository

**提交：** `46a700c`（实现） + `e3f3bf0`（测试） + `156d775` / `33f9634`（尾部算法修复）

- [x] 13 个 Repository（构造注入 + 实例方法）
- [x] 5 个尾部算法类（_ExamFilterEngine, _ExamGenerator, _RecommendationEngine, _StatisticsAggregator, _PointsCalculator）
- [x] Repository 集成测试 57 用例
- [x] helper 测试（question_status_helper 11 用例）
- [x] PDF helper 实现

## 2.5 — 同步引擎 + 更新机制

**状态：** 进行中（未完成）

- sync_types.dart — ✅ 基础枚举定义
- sync_pusher.dart — ✅ 推送核心骨架
- sync_manager.dart — ✅ 总入口骨架
- update_manager.dart — ❌ 仅 2 行占位，未实现
- 更新机制测试（4 条）— ❌ 因函数未实现而失败

---

## 测试汇总（当前）

- `flutter test` — 214 passed, 4 failed（4 失败全因 update_manager 未实现）
- 服务端 pytest — 89 passed
