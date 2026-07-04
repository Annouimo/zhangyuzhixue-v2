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
| 组卷（一级页） | `exam.html` | 新组卷入口 + 3个列表项入口 |
| 智能组卷 | `paper_auto.html` | 筛选+题型 stepper+难度调优 |
| 自主选题 | `paper_pick.html` | 筛选+逐题勾选+底部固定条 |
| 发现组卷 | `paper_explore.html` | 浏览他人公开试卷+4种排序+点赞+收藏 |
| 我的组卷 | `paper_history.html` | 自己创建的试卷列表+公开/私密开关 |
| 我的收藏 | `paper_favorites.html` | 收藏的他人试卷 |
| 试卷预览（自己） | `paper_quicklook.html` | 公开开关+删除 |
| 试卷预览（他人） | `paper_quicklook_other.html` | 点赞+收藏+快对答案 |

### 注意

- `paper_builder.html` 已废弃
- 自主选题跨筛选保留：独立维护 `Set<int> selectedIds`
- 题型默认值（选10填5解6）及高考参考难度从 DB 读取
- 点赞和收藏需服务端接口

---

## 学习偏好

筛选方案功能统一更名为"学习偏好"。

| 页面 | 路径 | 说明 |
|------|------|------|
| 偏好管理 | `preference_list.html` | 列表 + 编辑/删除 |
| 偏好编辑 | `preference_edit.html` | 新建/编辑偏好 |
| 首次引导 | `preference_welcome.html` | 注册后无偏好时引导创建 |
| 推荐页 | `recommend.html` | 两种模式切换：智能推荐 / 偏好推荐 |

### 实现注意

- 登录/注册成功 → 检查 `preference.count` → 0 则跳转 `preference_welcome.html`
- 推荐页自动切换规则：做题<5题且存在偏好 → 默认偏好推荐；做题≥5 → 默认智能推荐
