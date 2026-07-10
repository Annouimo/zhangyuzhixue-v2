# Phase 1.5 — 执行记录

> 执行日期：2026-07-10 | 对应计划文档：Phase-1.5-Staging部署.md

---

## 执行结果

| 步骤 | 内容 | 结果 |
|:----|:-----|:----:|
| **0** | 服务器安装 Python 3.11（deadsnakes PPA） | ✅ |
| **1** | bare repo + post-receive hook | ✅ |
| **1b** | 本地 `git push server master` | ✅ |
| **2** | scp `.env` 到服务器并配置 | ✅ |
| **3** | systemd gunicorn 服务（workers=2, timeout=120s） | ✅ |
| **4** | nginx 配置（/static/ 直出 + /api/ proxy_pass + 维护页兜底） | ✅ |
| **5** | 验证部署（curl API 全通） | ✅ |
| **6** | 首次构建 assets/lectures.db | ✅ |
| **7** | 创建 Dev 用户 + 全量验证 | ✅ |

## 产出确认

- [x] Server 代码在 ECS 上运行，systemd 管理
- [x] 通过 `zhangyuzhixue.top` 可访问 Swagger API 文档（已验证 200 ✅）
- [x] 认证 API（login/register）可调通（已验证 405/401 正确响应 ✅）
- [x] 构建脚本首次运行成功，产物就位（qbank_v4.db.gz / lecture_v3.db.gz ✅）
- [x] Dev 测试用户可登录
- [x] 维护页面可快速切换回退

## 相关提交

- `31d8f71` — docs: Phase 1.5 Staging 部署细化方案
- `a5b10fd` — 补充基础设施：CI/CD、Sentry、Staging 等
