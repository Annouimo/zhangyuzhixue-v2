# data-db 标记规范

> 本文档定义 HTML 原型中 `data-db` 标记体系的完整规范，是 HTML 原型与 Flutter Repository 之间的映射契约。

---

## 一、标记总览

| 属性 | 含义 | 示例 | 对应 Flutter 层 |
|------|------|------|----------------|
| `data-db` | 📖 只读显示 | `data-db="user.getInfo.realName"` | Repository 方法返回值 |
| `data-db-bind` | 🔄 双向绑定 | `data-db-bind="auth.login.username"` | TextEditingController + 初始值 |
| `data-db-action` | ✏️ 写入操作 | `data-db-action="rating.submit()"` | Repository 写入方法 |
| `data-db-loop` | 🔁 列表循环 | `data-db-loop="assign.getPending"` | ListView.builder 数据源 |
| `data-db-empty` | 📭 空状态文案 | `data-db-empty="暂无待办作业"` | 列表为空时的占位 |

## 二、路径命名规范

```
格式：{repo缩写}.{方法名}[].{字段名}
```

- 首段：Repository 类名去掉 `Repository` 后首字母小写（`assign` ← `AssignmentRepository`）
- 中段：Repository 的方法名，camelCase
- `[]`：列表中的单个元素
- 尾段：返回对象的字段名，camelCase

**示例：**

```
data-db="assign.getPending[].title"
         assign  ← AssignmentRepository
                 getPending  ← getPending()
                          title  ← AssignmentSummary.title

data-db-action="exam.downloadPdf(1)"
                exam  ← ExamRepository
                     downloadPdf  ← downloadPdf()
```

## 三、标记颜色辅助（仅在原型中）

`styles.css` 中对标记了 `data-db` 的元素加了背景高亮，仅用于原型开发阶段：

```
[data-db]       → 浅黄底色 + 橙色虚线下划线
[data-db-loop]  → 蓝色虚线边框
```

## 四、SharedPreferences 标记说明

SharedPreferences **不纳入 `data-db` 标记体系**。原因：
- SharedPreferences 不直接驱动 UI 渲染（token、冷却时间、版本弹窗记录均为后台状态）
- `data-db` 的意义是「指着 HTML 元素说数据来自 Repository 的哪个方法」，原型评审者不需要看 key 名

SharedPreferences key 在 Flutter 代码中各页面的 `_Prefs` 类中声明，详见 [Flutter代码规范.md](../05-Flutter/Flutter代码规范.md) 的页头编译常量规范。

## 五、LaTeX/MD 渲染标注

以下 data-db 路径的值可能含 Markdown 和/或 LaTeX 数学公式，Flutter 实现时统一用 `MdLatexBody` 组件渲染。该组件位于 `lib/widgets/md_latex_body.dart`，封装了 `flutter_markdown_plus` + `flutter_math_fork`，支持 `$...$` 行内公式和 `$$...$$` 块级公式。

| data-db 路径 | 内容类型 | 出现页面 |
|-------------|---------|---------|
| `question.getDetail.stem` | 题干 Markdown + LaTeX 公式 | solve-choice/fill/solve (题干区) |
| `progress.getSolveState.subQuestions[].solutions[].steps[].analysis` | 步骤解析 LaTeX 公式 | solve-solve (步骤解析区) |
| `lecture.getContentParsed.pages[].blocks[]` | 讲义正文 Markdown + LaTeX（解析后：pages 外层循环，blocks 内层循环） | lecture_content |
| 知识卡片弹层内容 | 卡片说明 LaTeX | solve-solve, lecture_content |
| `question.getDetail.conceptTags` | 概念标签列表（用 Chip + Wrap 渲染，非 LaTeX） | solve-choice/fill/solve |

---

> 相关文档：
> - [Flutter代码规范.md](../05-Flutter/Flutter代码规范.md) — Repository 层规范
> - [数据库结构设计.md](../02-数据/数据库结构设计.md) — 数据库表定义
