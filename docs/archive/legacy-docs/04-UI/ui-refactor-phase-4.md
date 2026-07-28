# UI 重构第四批说明

本批覆盖考试组卷、作业讲义、统计、个人中心等剩余学生端页面。

## 改动范围

### 考试与组卷（8 文件）
- 考试列表、详情、历史记录、收藏试卷、自主组卷、筛选条件、结果统计、答题卡

### 作业与讲义（4 文件）
- 作业列表和状态、作业详情、讲义列表、讲义阅读
- 待完成/逾期等状态表达、下载/查看/开始学习操作

### 统计页面（2 文件）
- 学习时长、正确率、知识点掌握度、练习趋势、错题分布
- 图表和数据卡片、手机与宽屏布局

### 个人中心（1 文件）
- 用户信息、设置项、同步状态、深色模式、退出登录

### 新增共享组件（2 个）
- `AppFeatureBanner` — 功能特点展示横幅
- `AppMetricCard` — 指标数据卡片

## 兼容适配
- `AppIcons.like` / `AppIcons.likeSelected` — 收藏图标别名
- `AppMotion.standard` — 300ms 标准动画时长
- `AppShadows.low` — 低层级阴影别名
- `AppContentContainer.useSafeArea` — SafeArea 开关

## 文件清单
- `Phase4/ui-refactor-phase4.patch` — 第四批补丁文件
