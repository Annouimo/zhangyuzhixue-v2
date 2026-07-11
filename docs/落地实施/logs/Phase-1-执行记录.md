# Phase 1 — 执行记录

> 执行期间：2026-07-10 | 对应计划文档：Phase-1-服务端全量.md

---

## 1.1 — 5 App models.py + migrate

**提交：** `507e026`

- [x] 5 App 全部 models.py 实现，零 check 问题，40+ 自定义迁移
- [x] admin.py 全部注册（list_display / search_fields / filter_horizontal 配置）

## 1.2 — 题库数据迁移

**提交：** `913fb62`

- [x] 798 题迁移完成（ID 按试卷重排）
- [x] ConceptTag 127 条（三级树形重构）
- [x] SubQuestion 1092 + SolutionMethod 1152 + SolutionStep 3061
- [x] ChoiceExt 350/380（30 题解析失败，待补）
- [x] 配图 204 题匹配 → `static/questions/images/`
- [x] 全文审核文件 20+ 个 → `server/migration_audit/`（后迁移至 `docs/_archive/migration_audit/`）

## 1.3 — JWT 认证 API

**提交：** `2f0b0c8`

- [x] 4 个认证端点可调用（login/register/refresh/logout）
- [x] Dev 测试用户就绪（admin/teacher1/student1-3）
- [x] Swagger 文档可访问（`/api/docs/`）
- [x] pytest 4 场景全部通过

## 1.4 — 同步 API

**提交：** `93484ea`

- [x] 版本检查（qbank/lecture）× 2 端点
- [x] sync push（6 种 entity_type batch 处理）
- [x] pytest 28 测试通过

## 1.5 — 用户/组卷/讲义 API

**提交：** `4c1e294`

- [x] 用户 API（me/avatar/level-percentile）可调用
- [x] 课程/章节目录/讲义内容 API 可调用
- [x] pytest 12 测试通过

## 1.6 — 构建脚本

**提交：** `b4698e4`（实现） + `49225d5`（测试）

- [x] assets.db.gz 可构建（含 14 个表，798 题）
- [x] lectures.db.gz 可构建
- [x] --test 模式不更新版本号
- [x] pytest 26 场景全部通过

## 1.7 — PDF 视图

**提交：** `e2708b3`

- [x] request-token API + pdf/view 路径可访问
- [x] HTML 渲染含 KaTeX 公式
- [x] 签名验证（过期/无权限 → 403）

## 1.8 — Admin tools

**提交：** `1b1c02d`

- [x] Admin tools 页面可用（`/admin/system/tools/`）
- [x] 构建按钮（题库+讲义）可点击
- [x] 邀请码生成 + 列表展示可用

---

## 验证汇总

- `python manage.py check` — 零问题 ✅
- `flake8` — 零问题 ✅
- pytest（`accounts/ courses/ interactions/ system/`）— 全通过 ✅
