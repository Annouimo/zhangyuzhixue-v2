# 章鱼智学 · 自动化审查流程手册

> 对应 Hermes skill：`auto-project-owner-acceptance`
> 旧版手动审计：`project-owner-acceptance`（保留备用）
> 旧版手册：`docs/auto-audit/审查流程手册_旧版.md`

---

## 一、核心理念：R0 文档清单先行

**每次审计的第一步，是从权威来源文档机械提取完整清单，然后逐项验证代码。不是从代码出发找文档确认。**

```
正确流程：
  权威来源文档 → 提取完整清单 → 逐项验证代码是否存在/正确
                                  ↑
                          自动化引擎完成 CERTAIN 检查
                          人工完成 LIKELY/SUSPICIOUS 审核

错误流程（已被 R0 禁止）：
  看代码 → 发现某个东西存在 → 找设计文档确认 → 标记为 ✅
```

---

## 二、审计分类速查（A-G）

| 类别 | 名称 | 覆盖文件夹 | 引擎模块 | 权威来源文档 |
|------|------|-----------|---------|-------------|
| **A** | 服务端审计 — Django | `server/accounts/qbank/courses/interactions/system/math_platform/templates/static/` | ①存在性 ③声明 ④标记 ⑤测试 | `02-数据/数据库结构设计.md` + `03-服务端/API设计.md` |
| **B** | Flutter 数据层 | `flutter_app/lib/data/` + `flutter_app/lib/domain/` + `flutter_app/pubspec.yaml` + `flutter_app/assets/` | ①存在性 ③声明 ④标记 ⑤测试 ⑥stub | `02-数据/数据库结构设计.md` + `05-Flutter/Repository/*.dart`（设计稿） + `05-Flutter/图片路由规范.md` |
| **C** | Flutter UI 审计 | `flutter_app/lib/pages/` + `flutter_app/lib/widgets/` + `flutter_app/lib/main.dart` + `flutter_app/lib/app_theme.dart` | ①存在性 ②HTML→Flutter ④标记 ⑤测试 ⑥stub ⑦导航 | **`04-UI/html/*.html`（全部 31 个）** |
| **D** | 教师端审计 | `server/` + `landing/` + `landing/teacher/` | ①存在性 ③声明 ④标记 ⑤测试 | `06-教师端/html/*.html` + `06-教师端/教师端功能边界.md` |
| **E** | 部署审计 | `.github/` + `server/scripts/`（备份/构建） | ①存在性 ③声明 ④标记 | `备份方案.md` + `03-服务端/服务端架构.md §五` |
| **F** | 数据迁移审计 | `docs/_archive/migration_audit/` + `server/scripts/dump_data.py` + `server/scripts/load_data.py` | ①存在性 ④标记 | `落地实施/Phase-1.2-题库数据迁移.md` |
| **G** | 全项目横切 | 全项目（不特定文件夹） | ④标记 ⑥stub | `07-工作流/开发工作流程.md` + `测试策略.md` + `备份方案.md` |

### 命令汇总

每条审计命令 = `skill 加载 + 引擎执行 + 目标路径`：

```bash
# Type A — 服务端
skill_view(name='auto-project-owner-acceptance')
python docs/auto-audit/audit_engine.py <workspace> --type A

# Type B — Flutter 数据层
python docs/auto-audit/audit_engine.py <workspace> --type B

# Type C — Flutter UI
python docs/auto-audit/audit_engine.py <workspace> --type C

# Type D — 教师端
python docs/auto-audit/audit_engine.py <workspace> --type D

# Type E — 部署
python docs/auto-audit/audit_engine.py <workspace> --type E

# Type F — 数据迁移
python docs/auto-audit/audit_engine.py <workspace> --type F

# Type G — 全项目横切
python docs/auto-audit/audit_engine.py <workspace> --type G

# 全量运行（所有类别）
python docs/auto-audit/audit_engine.py <workspace>
```

**补充人工检查（每种类型完成后）：** 见 §四 完整审计流程 → Step 3-5 人工判断清单。根据类型不同，需侧重的人工检查不同：

| 类型 | 人工重点 |
|------|---------|
| A | 模型字段值正确性、API 端点返回值链 |
| B | Repository 方法签名 vs 设计稿、数据流追踪 |
| C | HTML ↔ Flutter 元素感官比对、异常处理充分性、底部导航 |
| D | 功能边界是否超出学生端范围、API 权限 |
| E | 服务器端实际配置（systemctl/crontab）— 引擎无法远程检查 |
| F | 数据行数核对、字段内容随机抽样 |
| G | 设计文档状态标记是否过时 |

---

## 三、自动化审计引擎

### 文件位置

`docs/auto-audit/audit_engine.py`

### 执行方式

```bash
# 全量（所有模块）
python docs/auto-audit/audit_engine.py <workspace_path>

# 按类别（只跑该类别相关模块）
python docs/auto-audit/audit_engine.py <workspace_path> --type C
```

### 检查范围（7 个模块）

| 模块 | 检查内容 | 输出置信度 | 适用类型 |
|------|---------|-----------|---------|
| ① | 全覆盖矩阵要求的目录/文件是否存在 | CERTAIN | A B C D E F |
| ② | HTML 原型 → Flutter 页面一对一覆盖 | CERTAIN | **C** |
| ③ | pubspec.yaml 资产声明 vs lib/ 引用一致性 | CERTAIN | **B** |
| ④ | 设计文档"待完成/待定/预留"标记提取 | CERTAIN | A B C D E F G |
| ⑤ | 测试文件覆盖率（每个 page 应有 test） | CERTAIN | A B C D |
| ⑥ | 代码 stub/TODO/简化标注扫描 | SUSPICIOUS | B C G |
| ⑦ | 导航架构（HTML 底栏 Tab vs Flutter MainShell） | CERTAIN | **C** |

### 输出格式

每条问题输出一行：

```
置信度 | 问题描述 | 来源文档 | 涉及路径 | 证据链摘要
```

置信度三档：

| 置信度 | 含义 | 处理方式 |
|--------|------|---------|
| **CERTAIN** | 铁定有问题。设计文档明确要求、磁盘不存在、代码确实没有 | 直接采纳。审计员不需要看，进报告 |
| **LIKELY** | 很可能是问题。有替代方案但不完全一致 | 需要审计员确认 3 分钟/条 |
| **SUSPICIOUS** | 模式可疑但不确定。如 return [] 可能是合法的空列表返回 | 需要审计员判断是否升级 |

---

## 四、人工补充审查（自动化不覆盖的部分）

自动化引擎跑完后，审计员还需要完成以下人工判断：

### 4.1 审核自动化输出（SUSPICIOUS 级别）

| 来源 | 内容 | 预计耗时 |
|------|------|---------|
| SUSPICIOUS 可疑项 | stub/TODO 扫描结果 | 每条 3 分钟 |
| 模块 ⑥ 扫描结果 | 判断 return [] 是真 stub 还是合法的空值返回 | 每条 1 分钟 |

### 4.2 流程追踪（R2 — 自动化不做）

自动化引擎检查"组件是否存在"，但**不会检查"返回值链是否完整"**。审计员必须手动执行以下流程追踪：

```
Source → Step1 → Step2 → Step3 → Sink

在每个箭头处检查：
  └─ {上一步} 的输出被 {下一步} 捕获了吗？
  └─ 返回值赋值了吗？(var x = f() vs f())
  └─ 数据类型在定义文件之外被引用了吗？
  └─ 有 UI 组件或持久化层消费它吗？
```

需要做流程追踪的功能点：

- 登录 → JWT 刷新链
- 同步推送 → enqueue → push → server_ids 返回
- 更新检查 → checkAll → 返回值消费
- 评分提交 → sync 入队 → 积分赠送 → 冷却设置
- PDF 下载 → token 生成 → 签名验证

### 4.3 异常处理充分性（四维③ — 自动化不做）

自动化只能找到 `catch` 块的存在，但无法判断处理方式是否充分。审计员需要检查：

| 页面 | 检查点 |
|------|--------|
| 所有 solve 页面 | catch 块是静默还是展示 SnackBar/ErrorPlaceholder? |
| IndexPage | 无加载态（StatelessWidget）— 需要改为 StatefulWidget 吗？ |
| StatisticsPage | catch 块有 ErrorPlaceholder 吗？ |
| ProfileEditPage | 提交失败时有错误提示吗？ |

### 4.4 设计合规（四维① — 自动化做存在性，人工做正确性）

自动化检查"这个字段存在吗？"——审计员检查"这个字段的值对吗？"

例如：
- 自动化：检查 `BaseQuestion.difficulty` 字段在 models.py 中存在 ✅
- 人工：检查 `FloatField()` 的范围是 0-10，默认值合理，choices 正确

### 4.5 敷衍应付识别（四维④ — 自动化扫描，人工判定）

自动化扫描出 `// TODO` 和 stub 模式，但审计员需要判定每个扫描结果是：

| 判定 | 条件 | 处理 |
|------|------|------|
| 真 stub | return [] 会被调用方误以为"无数据" | 标记为 ❌ 问题 |
| 合法空值返回 | if (list.isEmpty) return [] 是防御性编程 | 标记为 ✅ 正常 |
| 过时 TODO | TODO 旁边的代码已实现 | 标记为 ⚠️ 清理建议 |

---

## 五、完整审计流程

```
┌──────────────────────────────────────────┐
│  1. 确定审计类型 (A-G)                    │
│     查阅 §二 速查表                       │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  2. 运行对应类别的引擎                     │
│     python audit_engine.py <ws> --type C  │
│     产出：CERTAIN ❌ + SUSPICIOUS 清单    │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  3. 审核 SUSPICIOUS 级别                  │
│     人工：判断是否升级或放行               │
│     约 30-60 分钟                         │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  4. 流程追踪（R2）                         │
│     人工：逐箭头追踪返回值链               │
│     约 30-60 分钟                         │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  5. 异常处理 + 设计合规 + 反敷衍审核       │
│     人工：异常充分性、值正确性、简化判定    │
│     约 30-90 分钟                         │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  6. 合成最终报告                           │
│     自动化 CERTAIN + 人工判定结果          │
│     六维评分                              │
└──────────────────────────────────────────┘
```

**总耗时（估计）：**
- 自动化执行：< 30 秒
- 人工审核 SUSPICIOUS + 流程追踪 + 异常判定：约 2-3 小时
- 对比纯手动审计：节省约 60% 时间，且 CERTAIN 检查零遗漏

---

## 六、当自动化与人工判断冲突时

| 情况 | 处理方式 |
|------|---------|
| 自动化报 CERTAIN，人工判断认为误报 | **以人工为准，但必须记录。** 在审计报告中标注"自动化报 ❌ 但人工确认为 ✅ 正常"，并写理由。累计 3 次同类误报则改进脚本。 |
| 自动化没报，人工发现问题 | **以人工为准。** 在审计报告中单独列出。分析为什么自动化没发现，改进脚本。 |
| 自动化报 CERTAIN，人工没看到 | **自动化胜出。** 回退到自动化证据链，逐条确认。如果确认是误报，则第一条处理。 |

---

## 七、版本回退机制

如果发现自动版本有问题（大量误报或漏报），可以立即回退到手动审计：

```bash
# 切换到手动版本
skill_view(name='project-owner-acceptance')

# 如有必要，卸载自动 skill
skill_manage(action='delete', name='auto-project-owner-acceptance')
```

手动 skill 和手册均已保留未改动，位于：
- Skill: `project-owner-acceptance`
- 手册: `docs/auto-audit/审查流程手册_旧版.md`

---

> 版本：2.0 | 最后更新：2026-07-11
> 对应 Hermes skill：`auto-project-owner-acceptance`
