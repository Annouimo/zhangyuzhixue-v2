# 数据架构

最后核验：2026-07-28

## 服务端数据库

Django 数据模型分布在 `accounts`、`qbank`、`courses`、`interactions` 和 `system`。生产使用 SQLite WAL，备份必须使用 SQLite Online Backup API。

## 客户端数据库

- `assets.db`：题库、解析、知识卡片、概念标签、成就和等级定义。
- `courses.db`：讲义系列、章节和讲义内容。
- `user.db`：学生资料缓存、作答、反馈、组卷、偏好、积分、成就和同步队列。

本地表定义位于 `flutter_app/lib/data/database/`，生成结果为同目录的 `*.g.dart`。服务端数据包 schema 位于 `server/scripts/build_schemas.py`。

讲义不再使用可访问课程 ID 白名单；所有认证学生可读取全部讲义。用户提交不再关联作业。
