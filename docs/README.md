# 项目文档

本目录以“现行事实、决策记录、历史归档”组织。

- `current/`：当前有效的产品、架构、数据、开发和运维说明。
- `decisions/`：影响长期维护的产品与技术决策。
- `archive/`：旧方案和实施记录，仅供追溯，不代表当前实现。
- `_archive/`：本机历史备份，不纳入版本控制，不作为项目文档来源。

代码和配置始终是最终事实来源。文档与实现冲突时，应在同一变更中修正文档。

## 现行入口

- [产品边界](current/product-scope.md)
- [仓库地图](current/repository-map.md)
- [系统架构](current/system-architecture.md)
- [数据架构](current/data-architecture.md)
- [API 概览](current/api-overview.md)
- [开发与测试](current/development-and-testing.md)
- [发布与运维](current/deployment-and-operations.md)

## 关键决策

- [移除旧教学平台](decisions/0001-remove-legacy-teaching-platform.md)
- [保留 courses 应用名称](decisions/0002-keep-courses-app-name.md)
