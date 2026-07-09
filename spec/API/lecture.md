# 讲义 API 设计说明

> ⚠️ **废弃标记**：本文档中的「版本更新检查」增量拉取方案已废弃。
> 讲义内容现已拆分到独立的 `lectures.db`，版本检查走统一 `GET /api/sync/lecture/version` API，整体下载 .db 文件替换。
> 详见 `docs/本地数据方案.md#二更新机制`。
>
> 其余内容（数据流、分隔符约定、客户端解析逻辑、本地表结构）仍为有效设计。

## 数据流（方案 B）

```
服务端 Document.md_content（含 <!--pagebreak--><!--reveal--> 的原始 markdown）
  │
  ├── asset 构建脚本：原样拷贝（不解析）
  │     → 客户端 assets lecture_content 表
  │
  └── API：原样返回 md_content（不解析）
        → 客户端 API 响应写入本地 lecture_content 表
        → 渲染器 parseMdContent() → LectureContentParsed
```

## 服务端 API

### GET /api/lectures/chapters/{chapterId}/content/

**响应格式：**

```json
{
  "chapter_id": 1,
  "title": "导数的几何意义",
  "md_content": "## 一、导数的几何意义\n函数 y = f(x) ...\n<!-- reveal -->\n**例 1**..."
}
```

**说明：**
- `md_content` 为 `Document.md_content` 原样返回，不做解析
- 响应中的 `chapter_id` 对应服务端 `Document.id`

### GET /api/lectures/courses/

**响应格式：**

```json
[
  {"id": 1, "name": "导数系统课", "chapter_count": 12},
  {"id": 2, "name": "三角函数专项", "chapter_count": 8}
]
```

### GET /api/lectures/courses/{courseId}/chapters/

**响应格式：**

```json
{
  "course_name": "导数系统课",
  "items": [
    {"id": 1, "title": "导数的概念与运算", "page_count": 8},
    {"id": 2, "title": "导数的几何意义", "page_count": 6}
  ]
}
```

**说明：**
- `page_count` 由服务端构建时从 `md_content` 解析计算（按 `<!-- pagebreak -->` 切分后长度）
- 客户端不依赖该值的精确性，UI 显示和渲染使用 parseMdContent 后的实际页数
- 设计目的仅为 Chapter 列表页显示「共 X 页」的参考信息

## 分隔符约定

| 分隔符 | 含义 | 说明 |
|--------|------|------|
| `<!-- pagebreak -->` | 分页标记 | 将上一页与下一页分开 |
| `<!-- reveal -->` | 展开块分割 | 同一页内，blocks[0] 默认可见，blocks[1..] 逐步展开 |

**注意：**
- 分隔符前后可以有空行，`parseMdContent()` 会 `trim()` 每个切分结果
- `<!-- pagebreak -->` 和 `<!-- reveal -->` 都是 HTML 注释语法，在标准 Markdown 预览器中**不可见**，不影响复习场景的滚动阅读
- 同一份 `md_content` 可用两种模式渲染：
  - 讲课模式：解析分隔符，生成分页 + 逐步展开
  - 复习模式（review=true）：忽略分隔符，全部渲染为单页

## 客户端解析

```dart
/// lectures/repository.dart 中定义的纯函数
LectureContentParsed parseMdContent(String mdContent, {bool review = false});
```

解析逻辑：
1. 先按 `<!-- pagebreak -->` 切分得到 pages
2. 每页再按 `<!-- reveal -->` 切分得到 blocks
3. 去除每段首尾空白，过滤空段

**缓存策略：** 解析结果用内存 `Map<int, LectureContentParsed>` 缓存，同一讲第二次打开不再重复解析。缓存不持久化到本地 DB。

## 本地数据库

### `lecture_content` 表（drift）

```sql
CREATE TABLE lecture_content (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_id  INTEGER NOT NULL UNIQUE REFERENCES chapter(id),
  title       TEXT NOT NULL,
  md_content  TEXT NOT NULL,    -- 镜像服务端 Document.md_content，含分隔符
  updated_at  TEXT              -- 版本时间戳
);
```

- 每行对应一讲（一个 Chapter）
- 构建脚本将原始 md 文件内容写入此表（不解析分隔符）
- API 同步时同样写入此表（覆盖 `chapter_id` 匹配的行）
- 读取时 `SELECT ... WHERE chapter_id = ?`

## ~~版本更新检查~~（已废弃）

> 此增量拉取方案已废弃，见文档顶部废弃说明。
> 本地 lecture_content 表仍然存在，数据改为随 lectures.db 整体下载替换。
