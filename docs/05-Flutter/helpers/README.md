# Helpers — 共享工具函数

跨 Repository 复用的纯逻辑，不依赖 Widget 层。所有 helper 放在 `lib/data/helpers/` 下。

| Helper | 职责 | 使用方 | 设计文档 |
|--------|------|--------|---------|
| `question_status_helper.dart` | 题目状态推算（已做/进行中/未做） | AssignmentRepository, RecommendRepository, ExamRepository | [数据库结构设计.md §10.2](../../02-数据/数据库结构设计.md#102-题目状态推算客户端) |
| `pdf_helper.dart` | PDF 下载流程（弹窗引导 → 请求 URL → 打开浏览器） | ExamRepository, AssignmentRepository | [PDF方案设计.md §3.2](../../03-服务端/PDF方案设计.md#32-共享-pdfhelper) |

**新增 helper**：仅在多处复用时才提取到 `helpers/`。单处使用的逻辑放在对应 Repository 文件内作为私有类。
