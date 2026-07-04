## 页面使用评价（退出弹窗）

弹出时机：返回按钮 20%概率（解题/试卷预览/讲义页面），同页 24h 冷却，停留>30s 触发。

**Flutter 实现注意**：
- `rating_repository.dart` 补 `savePageRating()` 方法
- 退出逻辑：在目标页面的 `Navigator.pop()` / back 回调中插入概率判断
- 冷却时间存本地 SharedPreferences 或 SQLite metadata
- 对话框用 `showDialog` 或自定义 Overlay

---

## 组卷功能升级（智能组卷 + 自主选题）

`paper_builder.html` 已废弃，入口改到 `exam.html` 一级页的两个整宽按钮。

| 页面 | 路径 | 积分 | 说明 |
|------|------|------|------|
| 智能组卷 | `paper_auto.html` | 10 | 筛选+题型数量+难度调优，系统自动生成 |
| 自主选题 | `paper_pick.html` | 20 | 筛选+逐题勾选，底部固定条始终显示确认按钮 |

**Flutter 实现注意**：
- `exam_repository.dart` 新增 `autoGenerate(counts, targetDifficulty)`、`getFilterPoolStats()`、`saveFilterPreset()`、`loadFilterPresets()`、`getExamDefaultCounts()`、`getGaokaoDifficultyRef()` 方法
- Drift 新增 `filter_presets` 表（name + JSON filters）
- 自主选题的跨筛选保留：独立维护 `Set<int> selectedIds`，不依赖筛选结果列表
- 难度调优上下限 = 当前筛选池中题目难度的实际极值，随筛选条件动态变化
- 题型默认值（选10填5解6）从 DB 读取
- 高考全卷参考难度（min/avg/max）从 DB 读取
