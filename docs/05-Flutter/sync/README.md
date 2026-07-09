# 同步引擎 · 设计稿

本目录包含同步引擎的 4 个 Dart 设计稿文件：

| 文件 | 内容 | 阅读顺序 |
|------|------|---------|
| `sync_types.dart` | 枚举（实体类型、操作类型、状态）+ 响应体模型 | ① 先看 |
| `sync_queue_dao.dart` | 队列表 CRUD 接口 + DAO 封装 | ② 其次 |
| `sync_pusher.dart` | 推送核心：出队 → 请求 → 处理结果 | ③ 然后 |
| `sync_manager.dart` | 总入口：enqueue / onAppStart / pushNow | ④ 最后 |

## 状态

这些文件是**设计稿**，不是可运行的代码。

- 未 import 任何其他模块（用注释标注了"定稿后替换"）
- 引用的外部类型（如 `SyncQueueDao`, `SyncApiInterface`）在同目录的其他文件中定义
- 存在大量 LSP 报错（未解析的引用），这是预期的

## 定稿后对接清单

1. 将 `sync_types.dart` 中的 `SyncQueueEntry` 替换为 drift 生成的 DataClass
2. 将 `sync_queue_dao.dart` 中的 `SyncQueueStore` 抽象接口替换为实际的 Drift DAO
3. 将 `sync_pusher.dart` 中的 `SyncApiInterface` 替换为真实的 `SyncApi` 实现
4. 将 `sync_manager.dart` 中的 `init()` 参数类型替换为真实的 `AppDatabase` 和 `SyncApi`
5. 补充各文件的 import 语句
