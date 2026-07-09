# 章鱼智学 · PDF 方案设计

> 本文档是 PDF 试卷浏览/打印的设计终稿。方案已确定，可直接进入编码阶段。

---

## 一、架构

### 核心理念

**Flutter 端不做任何 PDF 生成**。只保留入口按钮，点击后打开系统浏览器访问服务端 HTML 页面，用户通过浏览器自带的「打印→另存为 PDF」功能完成输出。

### 完整数据流

```
┌─ Flutter App ─────────────────────────────────┐
│                                                │
│  用户点击「下载 PDF」                           │
│    ↓                                           │
│  弹出提示弹窗（引导操作，可勾选"不再提示"）       │
│    ↓                                           │
│  打开系统浏览器                                 │
│  URL: /pdf/view?pid=123&sig=xxxx               │
│                                                │
└────────────────────────────────────────────────┘
         │  HTTPS
         ▼
┌─ Django 服务端 ────────────────────────────────┐
│                                                │
│  /pdf/view 视图                                 │
│    ├── 验证 sig（HMAC，5 分钟有效期）             │
│    ├── 查询 custom_paper + questions            │
│    ├── 查询 choice_ext（选项）、question（图片路径）│
│    ├── 组装 HTML（KaTeX CDN + CSS 模板）         │
│    └── 返回 HTML 页面                           │
│                                                │
└────────────────────────────────────────────────┘
         │
         ▼
┌─ 系统浏览器 ───────────────────────────────────┐
│                                                │
│  渲染 HTML → KaTeX 公式完美显示                  │
│  用户按下 Ctrl+P / Cmd+P （或菜单→打印）          │
│    ↓                                           │
│  系统打印对话框                                  │
│    ├── 选择「另存为 PDF」                        │
│    ├── 选择「打印」（连接打印机）                  │
│    └── 纸张选 A4，页眉页脚取消勾选                │
│                                                │
└────────────────────────────────────────────────┘
```

### 为什么走这条路

| 老方案（Flutter 端生成） | 新方案（服务端 HTML → 浏览器打印） |
|------------------------|--------------------------------|
| 需要 3 个平台的原生 PDF 代码（Android/iOS/Windows） | 零平台代码 |
| Headless WebView 的限制多（createPdf 仅 iOS/macOS） | 浏览器原生打印，无限制 |
| 字体需要打包到 App（+5-8MB） | 浏览器用系统字体 + CDN 字体 |
| 页眉页脚难去除 | 用户在打印对话框里自行取消 |
| Flutter 代码量大（HtmlBuilder + PlatformHelper） | Flutter 端：1 行 url_launcher |

---

## 二、服务端

### 2.1 URL 与授权

```
GET /pdf/view?pid={paper_id}&sig={signature}
```

**sig 生成：**

```
sig = HMAC-SHA256(
  key = PDF_SECRET_KEY（Django settings 中的独立密钥）,
  data = paper_id + ":" + student_id + ":" + expire_timestamp
)
```

- 有效期为 **5 分钟**
- 一次性：可以使用但没用严格的防重放（只是 PDF 浏览，非敏感操作）
- Flutter 端用当前 `access_token` 向 `/api/pdf/request-token` 换取临时 sig

**安全流程：**

```
Flutter 端（已登录）
  → POST /api/pdf/request-token
     Header: Authorization: Bearer ***
     Body: { paper_id: 123 }
  ← 200: { sig: "xxxxx", expire_in: 300, url: "/pdf/view?pid=123&sig=xxxxx" }

Flutter 端打开 url_launcher(url)
```

**权限规则：**
- 自己的组卷（`custom_paper.student = 当前学生`）— 允许
- 他人的公开试卷（`custom_paper.is_public = True`）— 允许
- 他人的私密试卷 — 拒绝，返回 403


### 2.2 视图流程

```
GET /pdf/view?pid={source_id}&type={source_type}&sig={signature}
```

URL 中 `type` 参数区分数据源：

- `type=paper`（默认）— source_id = custom_paper.id
- `type=assignment` — source_id = assignment.id

```python
def pdf_view(request):
    source_id = request.GET["pid"]
    source_type = request.GET.get("type", "paper")
    sig = request.GET["sig"]

    # 1. 验证签名
    student = validate_pdf_sig(sig, source_id)  # 返回 student 或抛出 403

    # 2. 查数据
    if source_type == "assignment":
        assignment = Assignment.objects.get(id=source_id)
        # 校验：该学生必须在 assignment 关联的班级中
        questions = AssignmentQuestion.objects             .filter(assignment_id=source_id)             .order_by("sort_order")             .select_related("question")
        title = assignment.title
    else:
        paper = CustomPaper.objects.get(id=source_id)
        # 校验：自己的试卷或公开试卷
        questions = CustomPaperQuestion.objects             .filter(paper=paper)             .order_by("sort_order")
        title = paper.title

    # 3. 组装 sections, 查 choice_ext, 查图片路径
    # 4. 渲染 HTML 模板
    return render(request, "pdf/paper_view.html", {
        "title": title,
        "sections": sections,
    })
```

### 2.3 HTML 模板

复用 `pdf/test_paper.html` 的 CSS + 排版规范。服务端侧只需：
- 将 KaTeX CDN 从 `cdn.jsdelivr.net` 改为**使用本地托管版本**（Django static/），避免 CDN 加载延迟
- 图片引用改为 `{% static 'questions/images/' %}{{ img_path }}`
- 去掉 `file:///` 相关逻辑

### 2.4 配图

- 构建脚本在生成 assets.db 的同时，将图片复制一份到 Django 的 `static/questions/images/` 目录
- HTML 中用 `{% static %}` 标签引用
- 图片格式保持 WebP

### 2.5 字体

不再打包字体到 App。浏览器端通过 KaTeX CDN 加载数学字体，正文使用系统字体：

```css
body {
  font-family: 'Noto Serif CJK SC', 'Source Han Serif SC',
               'SimSun', 'STSong', serif;
}
```

- Windows: SimSun（宋体）系统自带
- macOS: STSong 系统自带
- Android: Noto Serif CJK（如果系统有）
- 回退到 serif

如果希望更一致的体验，可以在 `static/` 中放一个 WOFF2 版本的字体文件，通过 `@font-face` 加载（用户首次访问时缓存）。

### 2.6 错误处理

#### 2.6.1 错误场景对照表

| 场景 | 服务端行为 | Flutter 端行为 |
|------|-----------|---------------|
| **sig 过期**（>5min）| 返回 403，页面显示「链接已过期，请重新下载」 | 弹窗提示「链接已过期」，用户确认后重新调 `requestPdfUrl` |
| **paper 不存在** | 返回 404，页面显示「试卷不存在或已被删除」 | 弹窗提示「试卷不存在」，用户确认后关闭 |
| **权限不足** | 返回 403，页面显示「无权访问该试卷」 | 弹窗提示「无法访问」，返回列表页 |
| **网络错误**（Flutter 侧） | — | 弹窗「网络连接失败，请稍后重试」+ 重试按钮 |
| **服务端渲染失败** | 返回 500，Django 显示错误页面 | 弹窗提示「服务器开小差了」，建议稍后重试 |

#### 2.6.2 自动续期

`requestPdfUrl` 返回的 `expire_in` 为 300。Flutter 端在 `expire_in < 60` 秒时自动重新请求，避免用户操作过程中 URL 失效。

```dart
// requestPdfUrl 返回后启动倒计时
Timer(Duration(seconds: expireIn - 60), () {
  // 重新请求新 sig
  final newUrl = await requestPdfUrl(paperId);
  _cachedUrl = newUrl;
});
```

#### 2.6.3 兜底

如果浏览器打开后 sig 已过期，Flutter 端无法拦截。用户在浏览器中看到「链接已过期」提示页，需返回 App 重新下载。

---

## 三、Flutter 端


### 3.1 入口按钮

在所有试卷预览页面添加「下载 PDF」按钮。**不额外消耗积分**（组卷时已扣）。

| 页面 | data-db-action | 权限 |
|------|---------------|------|
| `paper_quicklook.html`（自己的组卷预览） | `exam.preview.downloadPdf()` | 自己的试卷 |
| `paper_quicklook_other.html`（他人公开试卷预览） | `exam.previewOther.downloadPdf()` | 公开试卷 |
| `paper_history.html`（我的组卷列表） | `exam.myExams.downloadPdf(id)` | 自己的试卷列表 |
| `paper_favorites.html`（我的收藏列表） | `exam.favorites.downloadPdf(id)` | 收藏的公开试卷 |
| `paper_explore.html`（发现组卷列表） | 由各卡片 data-db-action 处理 | 公开试卷 |
| `homework_detail.html`（作业详情） | `assign.downloadPdf()` | 作业（source_type=assignment） |


### 3.2 共享 PdfHelper

PDF 逻辑抽取到 `lib/data/helpers/pdf_helper.dart`，与 `question_status_helper.dart` 同级，
供多个 Repository 复用。

```dart
// lib/data/helpers/pdf_helper.dart
class PdfHelper {
  static Future<String> requestPdfUrl({
    required int sourceId,
    required String sourceType,
  }) async {
    final response = await api.post('/api/v1/pdf/request-token', body: {
      'source_id': sourceId,
      'source_type': sourceType,
    });
    return response['url'];
  }

  /// 完整流程：弹窗引导 → 请求 URL → 打开浏览器
  static Future<void> downloadPdf({
    required int sourceId,
    required String sourceType,
  }) async {
    // 1. 弹出操作引导弹窗
    final shouldShowGuide = await _showPrintGuide();
    if (shouldShowGuide == null) return;

    // 2. 获取 URL
    final url = await requestPdfUrl(
      sourceId: sourceId,
      sourceType: sourceType,
    );

    // 3. 打开系统浏览器
    await launchUrl(Uri.parse('https://$domain$url'),
        mode: LaunchMode.externalApplication);
  }
}
```

各 Repository 的 `downloadPdf()` 统一委托给 `PdfHelper`：

```dart
// 在 ExamRepository 中
static Future<void> downloadPdf(int paperId) {
  return PdfHelper.downloadPdf(
    sourceId: paperId,
    sourceType: 'paper',
  );
}

// 在 AssignmentRepository 中（作业详情页）
static Future<void> downloadPdf(int assignmentId) {
  return PdfHelper.downloadPdf(
    sourceId: assignmentId,
    sourceType: 'assignment',
  );
}
```

### 3.3 用户引导弹窗

```
┌─────────────────────────────────────┐
│  📄 准备打印试卷                     │
│                                     │
│  试卷已生成，请在浏览器中完成打印：    │
│                                     │
│  🖥️ 电脑用户：                       │
│     按 Ctrl+P 打开打印对话框          │
│     选择「另存为 PDF」或直接打印       │
│                                     │
│  📱 手机用户：                        │
│     点击浏览器菜单 (⋮) → 分享         │
│     → 打印 → 选择「保存为 PDF」        │
│                                     │
│     纸张选择 A4，取消页眉页脚 ✓       │
│                                     │
│  □ 不再提示                          │
│                                     │
│       [取消]    [打开浏览器]          │
└─────────────────────────────────────┘
```

| 元素 | 说明 |
|------|------|
| **「不再提示」复选框** | 勾选后下次直接打开浏览器，不再弹窗。存 `SharedPreferences` key `pdf_guide_dismissed` |
| **「打开浏览器」按钮** | 调用 `url_launcher` |
| **「取消」按钮** | 不做任何操作，关闭弹窗 |

---

## 四、排版规范

| 项 | 设定 |
|------|--------|
| 纸张 | A4，CSS `@page { size: A4; margin: 2.5cm 2.0cm; }` |
| 分页规则 | 选择/填空连续，解答题每题独立起页 |
| 图片 | 靠右浮动，max-width 180px |
| 填空线 | CSS `.fill-blank { border-bottom: 1pt solid #333; }` |
| 分值 | 不显示 |
| 姓名区 | 标题下方：姓名/班级/学号填空线 |
| 页码 | 不加（浏览器打印对话框自带页码选项） |
| 页眉页脚 | 学生在打印对话框中取消勾选即可 |

---

## 五、决策记录

| 决策 | 选择 | 理由 |
|------|------|------|
| PDF 生成方式 | 浏览器打印 | 零平台代码、浏览器原生打印质量最高 |
| HTML 渲染位置 | 服务端 Django | Flutter 不做任何渲染，只传 paper_id |
| 授权方式 | HMAC 签名 URL，5 分钟有效期 | 不暴露用户 token，无需额外登录 |
| 配图存储 | Django static/ 目录 | 构建脚本同步，Flutter assets 和服务端共用同一份 |
| 字体 | 系统字体 + 回退 | 不再打包字体，减少 App 体积 |
| 用户引导 | 弹窗 + 不再提示 | 低频操作，引导一次后自动跳过 |
| 入口按钮 | 全部试卷预览页 + 列表页 | 覆盖自己的组卷、公开试卷、收藏、作业、推荐 |
| 公开试卷下载 | 允许 | 公开试卷可被任意登录学生下载 PDF |
| PDF 下载扣分 | 不扣 | 组卷时已扣积分，PDF 是输出格式而非独立消费 |

---

## 六、TODO（编码阶段）

### Flutter 端

| # | 内容 | 文件 |
|---|------|------|
| 1 | `requestPdfUrl()` API 调用 | `exam_repository.dart` |
| 2 | 弹窗引导组件 + `SharedPreferences` 记录 | 新组件 `lib/widgets/pdf_guide_dialog.dart` |
| 3 | 调 `url_launcher` 打开浏览器 | 同上 |
| 4 | 更新 `downloadPdf()` 为新的流程 | `exam_repository.dart` |

### Django 端

| # | 内容 | 文件 |
|---|------|------|
| 5 | `/api/pdf/request-token` 接口 | `server/interactions/views.py`（或新建 `server/pdf/`） |
| 6 | `PDF_SECRET_KEY` 配置 | `server/math_platform/settings.py` |
| 7 | `/pdf/view` 页面视图 + 签名验证 | `server/interactions/urls.py` + `views.py` |
| 8 | HTML 模板（基于 `test_paper.html`） | `server/templates/pdf/paper_view.html` |
| 9 | 构建脚本同步图片到 `static/questions/images/` | `server/scripts/build_assets.py` |
| 10 | 配图 `static/` 路径确认 | 构建流程 |

---

> 相关文档：
> - [API设计.md](API设计.md) — PDF 请求 token API
> - [页面设计说明.md](../04-UI/页面设计说明.md) — 组卷页面交互
> - [构建脚本设计.md](../02-数据/构建脚本设计.md) — 图片构建流程
