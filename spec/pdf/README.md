# PDF 生成引擎 · 设计稿

本目录包含 PDF 试卷生成器的设计文件：

| 文件 | 内容 | 阅读顺序 |
|------|------|---------|
| `README.md` | 架构设计、数据流、排版规范、决策记录 | ① 先看 |
| `pdf_exam_input.dart` | PDF 生成器的输入数据类定义 | ② 其次 |

## 状态

这些文件是**设计稿**，不是可运行的代码。

- 数据类使用 `final` + `const` 构造函数，符合现有 Repository 风格
- 未 import 任何其他模块
- 存在 LSP 报错（未解析的 `Uint8List` 引用），这是预期的

---

## 一、架构

### 分层

```
ExamRepository.downloadPdf(id)          ← Repository 层：薄转发
  └→ PdfExamInputBuilder.fromPaper(id)  ← 数据转换：custom_paper_question + question → PdfExamInput
       ↓
PdfExamService                          ← 服务层：PDF 生成总入口
  ├→ PdfHtmlBuilder                     ← 排版：PdfExamInput → HTML（含 KaTeX + CSS 模板）
  └→ PdfPlatformHelper                  ← 平台适配：HTML → Uint8List（PDF bytes）
       ↓
Uint8List → 写入临时文件 → 打开/分享
```

### 职责边界

| 模块 | 职责 | 不做什么 |
|------|------|---------|
| **PdfExamService** | 编排流程：输入 → HTML → PDF → 回调 | 不接触数据库、不关心数据来源 |
| **PdfExamInput** | 纯数据类，描述"要印什么" | 无逻辑、无渲染代码 |
| **PdfExamInputBuilder** | 从 DB 组装 PdfExamInput | 不负责 PDF 渲染 |
| **PdfHtmlBuilder** | 数据 → HTML 字符串（CSS + KaTeX CDN + 字体 + 图片嵌入） | 不接触平台 API、不做文件 IO |
| **PdfPlatformHelper** | 抽象：HTML → PDF bytes | 不关心排版内容、不碰数据库 |

### 为什么不放 Repository 里

PDF 生成**不是数据访问**，是**输出渲染**。将 PdfHtmlBuilder / PdfPlatformHelper 塞到 Repository 尾部会导致：

- 职责混杂：一个文件既查 DB 又排 HTML 又调浏览器
- 难以复用：作业列表、推荐页、讲义未来也可能导出 PDF
- 测试困难：HTML 模板 + 平台调用混合在一起
- 文件膨胀：CSS/字体/图片嵌入逻辑会占大量行数

这与 `question_status_helper`（跨 Repository 共享的业务逻辑抽出独立文件）是同一思路。

---

## 二、数据流

```
用户点击「下载 PDF」（paper_quicklook / paper_history）
  ↓
ExamRepository.downloadPdf(paperId)
  ↓
查询 custom_paper_question （按 sort_order 排序）
  ↓
查询 question + choice_ext + sub_question
  ↓
PdfExamInputBuilder.fromPaper(paperId)  →  PdfExamInput
  ↓
PdfExamService.buildPdf(input)
  ├── PdfHtmlBuilder.build(input)  →  HTML 字符串
  └── PdfPlatformHelper.print(html, options)  →  Uint8List
  ↓
写入临时文件（getTemporaryDirectory() + .pdf）
  ↓
打开系统分享 / 保存 / 预览
```

### PdfExamInput 的字段来源映射

| PdfExamInput 字段 | 来源 |
|---|---|
| `title` | `custom_paper.title` |
| `sections[].label` | 按 `question_type` 推导：一/二/三 |
| `sections[].typeName` | `question_type` → 选择题/填空题/解答题 |
| `sections[].scoreInfo` | 组内所有 `question.default_score` 累加 |
| `question.number` | 从 1 重新编号（按 `custom_paper_question.sort_order` 顺序） |
| `question.stem` | `question.stem`（纯 Markdown+LaTeX，不含 `<img>`） |
| `question.imagePaths` | `question.images` JSON list → assets 实际路径 |
| `question.type` | `question.question_type` |
| `question.choices` | `choice_ext.options` JSON → `PdfChoice[]` |

---

## 三、数据类定义

见 `pdf_exam_input.dart`。

核心类结构：

```
PdfExamInput
├── title: String
├── sections: List<PdfSection>    // 选择题 → 填空题 → 解答题
│   ├── label: String             // "一" / "二" / "三"
│   ├── typeName: String          // "选择题" / "填空题" / "解答题"
│   ├── scoreInfo: String         // "共40分"
│   └── questions: List<PdfQuestion>
│       ├── number: int           // 当前试卷内的题号
│       ├── stem: String          // 题干（含 LaTeX，不含 img 标签）
│       ├── imagePaths: List<String>  // 配图 assets 路径
│       ├── type: PdfQuestionType  // choice / fill / solution
│       └── choices: List<PdfChoice>?  // 仅选择题
│           ├── label: String     // "A" / "B" / "C" / "D"
│           └── content: String   // 选项文本
```

---

## 四、排版规范

### 4.1 纸张

A4（210mm × 297mm）。`@page { size: A4; margin: 2.5cm 2.0cm; }`

### 4.2 字体

**原则**：打包字体到 App 安装包，跨平台输出一致。

| 用途 | 字体 | 格式 | 预估体积 |
|------|------|------|---------|
| 正文 | Noto Serif CJK SC (思源宋体) Regular | WOFF2 | ~5-8MB |
| 大题标题 | Noto Serif CJK SC Bold | WOFF2 | (含在上方) |
| 公式 | KaTeX 字体包 (5个) | WOFF2 | ~200KB |
| 数字/英文 | 同正文衬线字体自带 | — | — |

字体文件作为 Flutter assets 打包，在 HTML 中通过 `@font-face` + `url('file:///...')` 引用。各平台路径通过 `PdfPlatformHelper` 获取。

**为什么不强依赖系统字体？**
- Android 无 SimSun（宋体），iOS 无 Noto Serif CJK
- 系统字体在 headless 渲染时可能因字体缺失导致 fallback 不一致
- 打包字体保证无论用户用哪国系统，试卷排版完全一致

### 4.3 分页规则

| 规则 | CSS 实现 |
|------|---------|
| **标题+选择题+填空题连续编排**，从第1页开始自然流式排列 | 三个 section 均不强制分页 |
| **单题不允许跨页**（全题型通用） | `.question { page-break-inside: avoid; }` |
| **整个解答题区另起新页** | `.section-solution { page-break-before: always; }` |
| **解答题内每道题独立起页** | `.section-solution .question { page-break-before: always; }` |
| 但第一道解答题紧跟在 section 标题后，不额外分页 | `.section-solution .question:first-of-type { page-break-before: avoid; }` |

**效果**：选择/填空题混排在一页或多页上，自然流动；单题不跨页。解答题从全新一页开始，每道解答题独占一页，剩余大量空白留给学生写过程。

### 4.4 配图

- 从 `question.images` JSON 字段读取配图文件名列表
- 图片已打包为 WebP 格式在 Flutter assets 中（v2 构建流程已确定）
- HTML 生成时：
  1. 优先 `file://` 引用 assets 解包路径（简单快捷）
  2. 若 WebView 有跨域/安全限制导致图片不显示，降级为 **base64 data URI** 嵌入
- 图片宽度限制：`max-width: 55%`（与 Python 原型一致），居中显示
- 无配图则不产生 `<figure>` 标签

### 4.5 答案

**学生版不含答案**（当前版本只做学生版）。

- `PdfQuestion` 中无 answer 字段
- HTML 模板不包含 `.answer-box` 区域
- 教师版（含答案）作为未来扩展，输入数据类预留 `answer` 字段空间

### 4.6 姓名/班级/学号

学生版试卷头部保留填空线：

```
姓名：___________  班级：___________  学号：___________
```

由 `PdfExamInput.showStudentInfo = true` 控制。

---

## 五、平台策略

| 平台 | 实现方式 | 状态 |
|------|---------|------|
| **Android** | `flutter_inappwebview` → headless WebView → `createPdf()` → 返回 `Uint8List` | 🚧 需 spike 验证 |
| **iOS** | `flutter_inappwebview` → WKWebView → `createPDF()` → 返回 `Uint8List` | 🚧 需 spike 验证 |
| **Windows** | `dart:io` Process → `msedge.exe --headless --print-to-pdf` | ⚠️ 主目标为移动端，桌面暂缓 |

### 为什么选客户端（不选服务端）

1. **服务器带宽有限**（3Mbps），PDF 文件 500KB-1MB，多人同时下载压力大
2. **离线可用**：题库已经在本地 assets.db 中，PDF 生成完全本地完成
3. **不走同步队列**：避免了"同步队列要不要支持二进制下载"的问题
4. **已有 Python 原型验证**了 HTML+KaTeX→Chrome→PDF 技术路径可行

### 移动端 WebView print 的已验证项 → 需 spike 验证项

| 项 | 状态 |
|----|------|
| `flutter_inappwebview` 加载含 KaTeX 的 HTML | ⚠️ 待验证 |
| KaTeX CDN 离线化（字体 + JS 打包） | ⚠️ 待验证 |
| `createPdf()` 返回的 PDF 中 LaTeX 渲染正确 | ⚠️ 待验证 |
| A4 尺寸在 Android PrintManager 中保持 | ⚠️ 待验证 |
| 分页规则（`page-break-inside` / `page-break-before`）生效 | ⚠️ 待验证 |
| 图片嵌入（file:// vs base64）哪种可用 | ⚠️ 待验证 |
| 自定义字体 `@font-face` + `file://` 在 WebView 中加载 | ⚠️ 待验证 |

---

## 六、决策记录

| 决策 | 选择 | 理由 |
|------|------|------|
| PDF 生成位置 | 客户端 | 3Mbps 带宽不足、离线可用、不走同步队列 |
| 渲染方案 | HTML+KaTeX → 浏览器 PDF | Flutter 生态无成熟的 LaTeX→PDF 方案，浏览器 KaTeX 渲染成熟 |
| 字体 | 打包到安装包 | 跨平台一致、不依赖系统字体 |
| 正文字体 | Noto Serif CJK SC（WOFF2） | 开源、印刷感强、中文覆盖完整 |
| 输出版本 | 仅学生版（无答案） | 当前需求；数据类预留教师版扩展空间 |
| 图片格式 | WebP | v2 构建流程已确定 |
| 分页策略 | CSS page-break 属性 | 浏览器原生支持，无需额外逻辑 |
| PDF 查看 | 下载到本地 → 系统分享/打开 | 不内置 PDF 阅读器，避免额外依赖 |
| 数据转换位置 | 独立的 `PdfExamInputBuilder` | 与 `question_status_helper` 同一思路，跨 Repository 可复用 |
| PDF 生成器位置 | `lib/services/pdf/` | 独立文件夹，不与任何 Repository 耦合 |

---

## 七、未来扩展（非现在做）

- **教师版 PDF**：含答案 + 分值标注 + 评分建议
- **答题卡**：选择题机读卡格式
- **多卷（A/B 卷）**：同一套题目不同排列
- **讲义导出 PDF**：`lecture_content` → PDF
- **推荐题单导出**：推荐页"下载为 PDF"
