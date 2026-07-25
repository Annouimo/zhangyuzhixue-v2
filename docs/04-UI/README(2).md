# 章鱼智学 UI 改造：第二批

上游源码基准：`3ff19e0bde5fdce177566a87567918ba12b83dc3`

本地工作分支：`ui-refactor`

## 本批提交

- `bed69a8 feat(student-home): redesign learning dashboard`
- `508c9d7 feat(recommendations): refresh recommendation experience`

本批建立在第一批最后一笔提交 `3a97e09` 之上。

## 改动范围

### 学生首页

- 将首页重构为“今日学习仪表盘”。
- 增加醒目的快速练习主行动区。
- 增加待办作业、今日练习、正确率、等级四项概览。
- 将作业与讲义整理成统一学习入口。
- 重构签到、七日进度、每日任务和等级积分展示。
- 增加手机单列与宽屏双栏布局。
- 重构同步状态提示和新手引导。
- 保留原有加载、签到、快速练习、路由和数据逻辑。

### 推荐页

- 增加推荐页说明区和题目数量概览。
- 重构智能推荐、偏好推荐模式切换。
- 使用统一表单样式重构偏好选择器。
- 重构推荐题卡，突出题型、难度、状态、推荐原因和主行动。
- 补充更明确的空状态，并让短列表也可下拉刷新。
- 保留原有推荐仓库、静默刷新和解题路由。

## 推荐合并方式

不要等所有批次完成后一次性合并，也不要每一批直接进入主分支。

建议建立长期集成分支：

```bash
git checkout -b ui-integration
```

每一批先合并到 `ui-integration`，完成编译、真机和视觉检查后保留；全部批次稳定后，再将 `ui-integration` 合并进主分支。

## 应用第二批增量补丁

前提：第一批已经应用。

```bash
git checkout ui-integration
git apply --check --whitespace=nowarn ui-refactor-phase2.patch
git apply --whitespace=nowarn ui-refactor-phase2.patch
```

也可以保留两笔提交：

```bash
git am ui-refactor-phase2-commits.patch
```

## 从原始基准一次应用第一、二批

```bash
git checkout -b ui-integration 3ff19e0bde5fdce177566a87567918ba12b83dc3
git apply --check --whitespace=nowarn ui-refactor-phase1-and-2.patch
git apply --whitespace=nowarn ui-refactor-phase1-and-2.patch
```

## 验证说明

当前环境没有 Flutter SDK，因此没有执行 `flutter analyze`、测试或平台构建。
已完成：

- `git diff --check`
- Dart 文件括号/分隔符平衡检查
- 相对 import 路径存在性检查
- 第二批增量补丁在第一批源码快照上的实际应用验证
- 累计补丁在原始源码快照上的实际应用验证
