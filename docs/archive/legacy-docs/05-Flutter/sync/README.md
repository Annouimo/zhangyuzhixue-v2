# 同步引擎 · 设计稿

> ⚠️ 本文档为早期设计稿，部分接口与当前实现不完全一致。
> **实际实现以 `lib/data/sync/` 目录下的源码为准。**

本目录包含同步引擎设计阶段的参考文件：

| 文件 | 内容 | 状态 |
|------|------|------|
| `sync_types.md` | 枚举定义设计（5种 → 实际8种） | 需更新 |
| `sync_queue_dao.md` | 队列表接口设计 | 需更新 |
| `sync_pusher.md` | 推送核心设计（`PushBatchResult.details` → 实际 `serverIds`） | 需更新 |
| `sync_manager.md` | 总入口设计（`init(Object, SyncApiInterface)` → 实际 `init(SyncQueueDao, SyncApi, DatabaseProvider)`） | 需更新 |

## 当前实现对照

### Entity Types（实际 8 种）

| 枚举值 | 服务端 entity_type |
|--------|-------------------|
| `submissionDetail` | `submission` |
| `stepFeedback` | `step_feedback` |
| `cardFeedback` | `card_feedback` |
| `rating` | `question_rating` |
| `exam` | `custom_paper` |
| `exitRating` | `exitRating` |
| `paperLike` | `paper_like` |
| `paperCollect` | `paper_collect` |

### 推送响应格式

实际 `PushBatchResult` 使用 `serverIds` Map（`Map<int localId, int serverId>`），而非设计稿中的 `details` 数组。

### SyncManager init 签名

实际 `init(SyncQueueDao queueDao, SyncApi api, DatabaseProvider dbProvider)`。

## 参考文件

- `lib/data/sync/sync_types.dart` — 实际枚举定义
- `lib/data/sync/sync_manager.dart` — 实际总入口
- `lib/data/sync/sync_pusher.dart` — 实际推送核心
- `lib/data/daos/sync_queue_dao.dart` — 实际 DAO 实现
- `lib/data/api/sync_api.dart` — 实际 API 客户端
- `server/interactions/serializers.py` — 服务端序列化器
- `server/interactions/views.py` — 服务端 SyncPushView
