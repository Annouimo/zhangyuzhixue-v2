# Flutter 性能巡检

## 目标

性能巡检在 Windows Profile 构建中启动真实应用，分为全页面快速扫描和重点路径深度复测，同时采集：

- Flutter Build/Raster 帧耗时
- 页面、Repository、DAO 和同步计算 Span
- 查询或计算涉及的数据规模
- 超过 100ms 的慢操作

## 运行

Flutter SDK 位于工作区外，按项目约定以提升后的沙箱权限串行执行：

```powershell
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite PerformanceScan -PerformanceDataScale Normal -PerformanceHotRuns 0
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Performance -PerformanceDataScale Normal
```

`PerformanceScan` 在一次应用启动内对主要页面各测一次，通常优先运行。它使用明确的页面类型和加载状态判断内容就绪，不建立严格基线；超过 500ms、出现严重帧或 Build/Raster P90 超过 33ms 的页面标记为 `REVIEW`。

`Performance` 保留给已确认的重点路径，执行冷状态一次和热状态三次，用于优化前后对比与回归门禁。不要在尚未发现问题时为所有页面执行重复深测。

不要同时启动其他 Flutter 测试或构建。性能数字只采信 Profile 结果，不使用 Debug 结果建立基线。

## 输出

报告写入：

```text
.hermes/tmp/performance/performance-latest.json
.hermes/tmp/performance/performance-latest.md
```

每次运行还会保留带时间戳的 JSON 原始报告。

测试不会读取或覆盖当前 Windows 用户的应用数据库。每次运行都会在
`.hermes/tmp/performance/runtime/<scale>` 重建隔离数据目录：题库和讲义来自仓库内置资产，用户作答为不含个人信息和答案文本的确定性合成数据。

三种规模分别为：

| 规模 | 合成作答数 | 用途 |
| --- | ---: | --- |
| Small | 20 | 快速确认旅程可运行 |
| Normal | 500 | 日常性能巡检与 CI |
| Large | 5000 | 数据增长压力检查 |

快速扫描固定使用 Normal 数据。Large 只复测题库、推荐、统计、历史和同步等数据敏感页面。重点旅程先运行一次冷状态，再运行三次热状态，报告输出冷状态、热状态中位数、P90 和最差值。

## 建立基线

同一台机器、同一数据规模连续成功运行至少三轮，然后生成中位数基线：

```powershell
1..3 | ForEach-Object {
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite Performance -PerformanceDataScale Normal
}
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\performance\build_baseline.ps1 -DataScale Normal -Runs 3
```

基线写入 `performance/baselines/normal.json`。Small 和 Large 使用同样流程生成各自文件。基线应提交到 Git，并且只在确认功能正确、机器环境稳定且性能变化符合预期后更新。

存在对应基线时，driver 自动计算每次旅程相对变化。单次操作超过 1500ms 或相对基线恶化超过 20% 会令 Performance Suite 返回失败。首次运行没有基线时状态为 `NO_BASELINE`，只报告绝对阈值。

## 初始阈值

第一轮只报告，不阻断构建。完成至少三轮基线后再启用回归失败阈值。

| 指标 | 关注 | 严重 |
| --- | ---: | ---: |
| 点击到首帧 | 100ms | 250ms |
| 本地普通页面内容就绪 | 500ms | 1000ms |
| 复杂页面内容就绪 | 1000ms | 1500ms |
| 单个内部 Span | 100ms | 500ms |
| UI 单帧 | 33ms | 100ms |
| 相对基线退化 | 20% | 35% |

## 数据规模

报告记录题目、作答和讲义章节数量。比较两次报告前，应确认这些数据规模接近。真实网络请求的耗时只能用于诊断，不作为稳定的回归阈值。

真实网络 E2E 应使用独立 Suite，只报告网络耗时，不更新本地性能基线，也不作为稳定回归门禁。

## CI

CI 必须使用固定 Windows runner，并保持 Flutter 命令串行。建议日常先运行 Normal 快速扫描，重点回归套件按需或在计划任务运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_tests.ps1 -Suite PerformanceScan -PerformanceDataScale Normal -PerformanceHotRuns 0
```

无论成功或失败，都上传 `.hermes/tmp/performance/performance-latest.json`、`performance-latest.md` 和本轮带时间戳 JSON。不同硬件 runner 的结果不能共用基线。

## 解读顺序

1. 先看 Markdown 中的 `Slowest Operations`。
2. 判断耗时发生在页面、Repository、DAO 还是纯计算。
3. 再检查对应 Journey 的 Build/Raster P90。
4. 数据加载慢但帧正常，优先优化查询和缓存。
5. 数据加载快但帧慢，优先检查公式、图片、图表和大列表构建。
6. 同一路径连续运行至少三次，以中位数作为基线。

## 当前覆盖

- 快速扫描：主 Tab、推荐、题库、套卷、试题篮、讲义、统计、资料、成就、等级、积分、历史、偏好、学习档案、成长中心、设置、同步、投稿、复习及主要做题页
- 深度复测：应用冷启动、主 Tab 往返、推荐并显示第一题、统计切换范围、题目详情进入做题页

下一步根据快速扫描的 `REVIEW` 排名补充交互级探针，例如题库筛选、试卷预览、组卷和连续下一题；只对实际慢页面运行 Normal/Large 深度复测。
