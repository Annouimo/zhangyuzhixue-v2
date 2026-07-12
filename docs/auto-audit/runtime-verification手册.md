# 章鱼智学 · 运行时审计流程手册

> 对应 Hermes skill：`runtime-verification`
> 对应审计引擎模块：⑫（运行态审计日志验证 + R12 模式分析）+ nav_engine（自动走查）+ vision_report（视觉交叉验证）
> 版本：2.0 | 最后更新：2026-07-12

**R（纯 NDJSON）：** `python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R`
**RV（全自动）：** `python docs/auto-audit/nav_engine/walker.py D:\Hermes\zhangyuzhixue_app_v2 && python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R && python docs/auto-audit/vision_report/merge_reports.py D:\Hermes\zhangyuzhixue_app_v2`
**Skill：** `/skill runtime-verification 执行 R/RV — ...，项目目录"D:\Hermes\zhangyuzhixue_app_v2"`

---

运行时审计检查的是 **app 实际跑起来之后的数据和画面**，与静态审计（project-owner-acceptance）互补。静态审计看代码对不对，运行态审计看数据和画面有没有问题。

---

## 一、一句话流程

> **你启动 app → agent 自动走查 35 页 + 断言 + 出报告**

你只需启动 app，不需要手动走查。

---

## 二、前置条件

### 2.1 测试账号（已有）

```
用户名: test_audit
密码:   test123
```

### 2.2 环境要求

| 项目 | 要求 |
|:----|:----:|
| 桌面 | 不锁屏，窗口不被遮挡 |
| DPI 缩放 | 建议 100%（影响 pyautogui 坐标精度） |
| Python 包 | `pip install -r nav_engine/requirements.txt` |
| NDJSON 日志 | `%TEMP%/zhangyuzhixue_audit.ndjson`（AUDIT_MODE 自动写入）|

### 2.3 截图位置

```
docs/auto-audit/screenshots/2026-07-12/
  index_full.png
  exam_home_full.png
  ...
```

---

## 三、完整流程（三步全自动）

### Step 1 — 启动带审计的 app

**👤 你手动做：**

```bash
cd D:\Hermes\zhangyuzhixue_app_v2\flutter_app
flutter run --dart-define=AUDIT_MODE=true
```

确认出现 `✓ Built build\windows\x64\runner\Debug\flutter_app.exe` 后，不要关闭终端，**去做别的事**。

---

### Step 2 — 让 agent 执行

**🤖 对 agent 说：**

```
/skill runtime-verification 执行 RV — 全自动运行时审计，项目目录"D:\Hermes\zhangyuzhixue_app_v2"
```

或者纯命令行：

```text
python docs/auto-audit/nav_engine/walker.py D:\Hermes\zhangyuzhixue_app_v2
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R
python docs/auto-audit/vision_report/merge_reports.py D:\Hermes\zhangyuzhixue_app_v2
```

---

### Step 3 — agent 自动执行三阶段

#### Phase 1 — 自动走查 + 截图（~2min）

```
nav_engine/walker.py:
  ① win32gui 定位 Flutter 窗口 → 调整 390×844 → 左上角
  ② 逐组 G1-G6 走查 35 页
     每页: pyautogui.click → 等渲染 → mss 定向裁剪窗口截图
  ③ 截图保存到 docs/auto-audit/screenshots/{date}/
  ④ NDJSON 日志自动写入 %TEMP%/zhangyuzhixue_audit.ndjson
```

#### Phase 2 — 并行分析（~3min）

| 任务 | 方法 | 耗时 |
|:----|:----|:----:|
| **R** NDJSON 断言 | `audit_engine.py --type R`（R12.1-R12.6） | ~30s |
| **V** 视觉分析 | `delegate_task` 分 3 个子 agent 并行 vision_analyze | ~3min |

Vision 检查内容（V1-V4）：
| 维度 | 查什么 | vision 提示词 |
|:----:|:------|:-------------:|
| V1 | 布局完整性 | 元素是否可见、有无重叠/溢出/白屏 |
| V2 | 数据正确性 | 提取屏幕数字 vs NDJSON 断言值做交叉验证 |
| V3 | 导航可达 | 底部 Tab、列表项点击确有反应 |
| V4 | 空状态 | 无数据时占位符/重试按钮是否存在 |

#### Phase 3 — 合并报告（~10s）

```
vision_report/merge_reports.py:
  按分组 G1-G6 合并 R 断言 + V 视觉结果
  产出最终报告
```

---

### Step 3b — 纯 R 模式（无屏/无截图回退）

如果环境不支持截图（CI/SSH/无桌面），或已有旧 NDJSON 文件：

```text
python docs/auto-audit/audit_engine.py D:\Hermes\zhangyuzhixue_app_v2 --type R
```

此时不走查、不截图、无 vision 交叉验证，纯 NDJSON 数据断言。~30s 出报告。

---

## 四、报告示例

```
══════ 章鱼智学 · 合并审计报告 (R + V) ══════

### 分组概要
  G1 核心导航:        ✅ R=通过  V=通过
  G2 组卷/试题浏览:    ⚠️ R=1个CERTAIN V=1个WARNING
  G3 解题流程:        ❌ R=3个CERTAIN V=1个FAIL（白屏）
  G4 讲义:            ✅ R=通过  V=通过
  G5 作业:            ✅ R=通过  V=通过
  G6 个人中心:        ⚠️ R=1个SUSPICIOUS V=通过

### CERTAIN ❌
  ❌ [G3] 运行时错误: LectureCoursesPage._load → SQL 错误
  ❌ [G3] SolveChoicePage 截图: 白屏（app 崩溃）
  ❌ [G2] DAO 查询返回 0 行: ProgressDao 870 次

### V1-V4 视觉检查
  G3 solve_choice_V1:     ❌ 白屏 — 应用已崩溃
  G6 index_V2_pending:    ⚠️ NDJSON=4 但截图显示"0 项"

### 截图
  docs/auto-audit/screenshots/2026-07-12/
```

---

## 五、引擎 12 项检查速览

| # | 查什么 | 级别 | 能查出什么问题 |
|---|-------|:----:|--------------|
| 1 | 页面覆盖 | LIKELY | 35 页实测覆盖率 |
| 2 | 字段是否为 null | CERTAIN | pendingCount 未加载 |
| 3 | 等级文字是否硬编码 | SUSPICIOUS | "Lv.5" 写死 |
| 4 | 跨页数据一致 | SUSPICIOUS | 首页≠作业页 |
| 5 | DAO 是否 0 行 | CERTAIN | assets.db 空表 |
| 6 | 服务端 vs 客户端对比 | CERTAIN | 799 vs 0 |
| 7 | 运行时错误 | CERTAIN | catch 块异常 |
| 8 | API 4xx/5xx | SUSPICIOUS | 端点错误 |
| 9 | **冷启动时序 (R12.1)** | CERTAIN | ensureOpen 前调用 |
| 10 | **DAO N+1 (R12.2)** | SUSPICIOUS | 798 次逐一查询 |
| 11 | **API 注入 (R12.3)** | CERTAIN | ApiClient 未注入 |
| 12 | **Logger 覆盖 (R12.5)** | CERTAIN/LIKELY | 35 页 vs 实际 |

---

## 六、常见问题

### Q: agent 说"未找到窗口"

确认 app 已在终端运行并且窗口可见。不要最小化。

### Q: vision 误判

降低提示词中样式要求，关注功能完整性。误判率高于 20% 时暂时跳过 V 阶段，只跑 R。

### Q: 可以只跑 R 吗？

可以。`audit_engine.py --type R` 不需要截图，只需要 NDJSON 日志存在即可。
