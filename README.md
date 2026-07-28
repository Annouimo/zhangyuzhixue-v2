# 章鱼智学

面向高中生的高考数学学习工具，包含题目练习、逐步解析、个性化推荐、组卷、公开讲义、学习记录、统计与离线同步。

## 项目组成

- `flutter_app/`：学生端 Flutter 应用。
- `packages/shared/`：学生端基础主题、组件和工具。
- `server/`：Django API、Admin 和离线数据包构建。
- `landing/`：公开静态官网。
- `scripts/`：测试、审计、发布、运维和资产工具。
- `assets/brand/`：品牌图标与 Logo 的单一来源。
- `docs/`：现行文档、决策记录和历史归档。

## 开始工作

先阅读 [文档入口](docs/README.md) 和 [仓库地图](docs/current/repository-map.md)。

常用验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Quick
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Student
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Server
```

Flutter SDK 和 Windows 环境约束见 `AGENTS.md`。生产操作前必须同时阅读 [发布与运维](docs/current/deployment-and-operations.md)。

## 产品边界

当前仓库不包含教师端、班级体系和作业发布。`server/courses` 负责公开讲义系列与讲义内容；名称保留原因见 [决策 0002](docs/decisions/0002-keep-courses-app-name.md)。
