# 章鱼智学 UI 重构第一批交付

上游基准提交：`3ff19e0bde5fdce177566a87567918ba12b83dc3`

本地工作分支：`ui-refactor`

本批次提交：

1. `2d0dc50 feat(ui): establish shared design system`
2. `3a97e09 feat(student-ui): refresh responsive main navigation`

## 文件说明

- `zhangyuzhixue-v2-ui-phase1-source.zip`：在你上传的完整源码快照上应用改动后重新打包，保留原压缩包中的全部文件，不包含 `.git` 和构建产物。
- `ui-refactor-phase1.patch`：从上游基准源码到第一批结果的普通 Git 补丁。
- `ui-refactor-phase1-commits.patch`：保留两笔提交信息的邮件格式补丁，可使用 `git am`。

## 应用普通补丁

请先确保当前仓库位于或接近基准提交：

```bash
git checkout -b ui-refactor-phase1
git apply --check --whitespace=nowarn ui-refactor-phase1.patch
git apply --whitespace=nowarn ui-refactor-phase1.patch
```

项目现有源码主要使用 CRLF 行尾，因此未加 `--whitespace=nowarn` 时，Git 可能显示行尾空白警告；这不代表补丁无法应用。

应用后由技术人员运行：

```bash
flutter analyze
flutter test
```

## 按提交应用

```bash
git checkout -b ui-refactor-phase1
git am --whitespace=nowarn ui-refactor-phase1-commits.patch
```

## 主要改动

- 完整补齐浅色、深色 `ColorScheme` 与全局 Material 组件主题。
- 新增字体、间距、圆角、控件尺寸、断点、内容宽度、动效、阴影和图标令牌。
- 新增 `AppButton`、`AppCard`、`AppContentContainer`、`AppSectionHeader`、`AppStatusBadge`。
- 学生端手机使用 Material 3 底部导航，中宽屏切换侧栏，宽屏展开品牌侧栏。
- 保留四个原业务入口、页面状态和刷新逻辑。

## 检查说明

本环境未安装 Flutter SDK，因此没有执行 `flutter analyze` 或实际编译。已完成：

- Dart 文件括号、字符串和注释结构检查；
- `AppSemanticColors` 构造字段、浅深色实例、`copyWith` 与 `lerp` 完整性检查；
- 在原始源码 ZIP 上执行 `git apply --check` 和实际应用；
- 补丁应用结果与本地分支的全部跟踪文件逐文件校验一致，同时保留原压缩包中的其他文件。
