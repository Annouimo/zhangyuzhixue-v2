# UI 重构第一批说明

基准版本：`3ff19e0bde5fdce177566a87567918ba12b83dc3`

本批次只建立视觉基础并调整学生端主导航，不改路由、数据访问、状态管理和业务流程。

## 颜色依据

所有颜色继续以《品牌颜色系统与深色模式设计规范 V1.0》为唯一依据：

- 品牌蓝只用于品牌展示；普通交互使用 `primary`。
- 智能推荐与收藏使用 `recommendation` 暖金色。
- 浅色和深色模式共用相同语义命名。
- 业务页面后续应通过 `context.colors` 取色，不新增任意硬编码颜色。

## 新增设计令牌

- `AppSpacing`：固定间距档位（xxs→xxl）。
- `AppRadius`：固定圆角档位（none→full）。
- `AppControlSize`：按钮和点击区域尺寸。
- `AppBreakpoints`：紧凑、中等和宽屏断点。
- `AppContentWidth`：表单、阅读、标准内容和仪表盘宽度。
- `AppMotion`：统一动画时长与曲线。
- `AppShadows`：浅色模式柔和阴影。
- `AppTypography`：中文学习场景字体层级。
- `AppIcons`：主导航与通用操作图标映射。

`AppSizes` 暂时保留为兼容入口，旧页面可逐步迁移。

## 补齐的全局主题

本批次统一了以下 Material 组件：

- AppBar、Card
- FilledButton、ElevatedButton、OutlinedButton、TextButton、IconButton
- TextField / InputDecoration
- ListTile、Chip
- Dialog、BottomSheet、SnackBar、Tooltip
- NavigationBar、NavigationRail、BottomNavigationBar
- Checkbox、Radio、Switch、ProgressIndicator、Badge

按钮包含默认、悬浮、按下、键盘焦点和禁用状态。输入框使用规范中的强边框及焦点边框。

## 新增共享组件

- `AppButton`：统一按钮类型、图标间距、全宽和加载状态。
- `AppCard`：统一卡片边框、选中态和可选悬浮层级。
- `AppContentContainer`：统一页面边距与最大内容宽度。
- `AppSectionHeader`：统一页面分区标题层级。
- `AppStatusBadge`：状态文字、图标和颜色联合表达。

这些组件已从 `package:shared/shared.dart` 导出。

## 学生端主导航

- 手机继续使用 Material 3 底部导航（NavigationBar）。
- 中等宽度（≥600dp）开始切换为侧边导航（NavigationRail）。
- 宽屏（≥840dp）侧边导航自动展开，并展示品牌标识和产品名称。
- 保留原有首页、推荐、组卷、个人中心入口及刷新逻辑。
- 个人中心仍显示待同步数量徽标。

## 后续页面迁移建议

页面改造时优先按以下顺序替换：

1. 零散 `TextStyle` 改用 `Theme.of(context).textTheme`。
2. 零散间距和圆角改用设计令牌。
3. 普通按钮和卡片改用共享组件。
4. 状态提示改用 `AppStatusBadge`，避免只靠颜色表达。
5. 页面主体用 `AppContentContainer` 控制宽屏阅读体验。
