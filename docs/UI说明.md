## 页面使用评价（退出弹窗）

弹出时机：返回按钮 20%概率（解题/试卷预览/讲义页面），同页 24h 冷却，停留>30s 触发。

**Flutter 实现注意**：
- `rating_repository.dart` 补 `savePageRating()` 方法
- 退出逻辑：在目标页面的 `Navigator.pop()` / back 回调中插入概率判断
- 冷却时间存本地 SharedPreferences 或 SQLite metadata

---

## 组卷功能

### 页面结构

| 页面 | 路径 | 说明 |
|------|------|------|
| 组卷（一级页） | `exam.html` | 新组卷入口 + 3个功能入口（列表项样式） |
| 智能组卷 | `paper_auto.html` | 筛选+题型 stepper+难度调优 |
| 自主选题 | `paper_pick.html` | 筛选+逐题勾选+底部固定条 |
| 发现组卷 | `paper_explore.html` | 浏览他人公开试卷+4种排序+点赞+收藏 |
| 我的组卷 | `paper_history.html` | 自己创建的试卷列表+公开/私密开关 |
| 我的收藏 | `paper_favorites.html` | 收藏的他人试卷 |
| 试卷预览（自己） | `paper_quicklook.html` | 公开开关+删除 |
| 试卷预览（他人） | `paper_quicklook_other.html` | 点赞+收藏+快对答案，无删除 |

### 两版预览页面

- `paper_quicklook.html` → 用户自己的试卷，有公开/私密开关、删除按钮
- `paper_quicklook_other.html` → 别人的试卷，有❤️点赞、🔖收藏按钮，无删除
- 区分方式：从 `paper_auto/paper_pick/paper_history` 链接到自己的，从 `paper_explore/paper_favorites` 链接到他人的

### 注意

- `paper_builder.html` 已废弃
- 自主选题跨筛选保留：独立维护 `Set<int> selectedIds`
- 题型默认值（选10填5解6）及高考参考难度从 DB 读取
- 点赞和收藏需服务端接口（多人操作，非纯本地）
