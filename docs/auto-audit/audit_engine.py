#!/usr/bin/env python3
"""
章鱼智学 · 自动化审计引擎
=====================
CERTAIN 级别检查（纯机械，零误报）。
输出格式：每条问题一行 | 置信度 | 问题 | 来源 | 路径 | 证据链
"""

import os
import re
import sys
from dataclasses import dataclass


# ═══════════════════════════════════════════════
# 配置
# ═══════════════════════════════════════════════

@dataclass
class Config:
    workspace: str = ""  # 从命令行参数或环境变量获取
    docs_dir: str = ""   # docs/ 目录
    flutter_lib: str = ""  # flutter_app/lib/
    server_dir: str = ""  # server/
    
    @classmethod
    def detect(cls, workspace: str):
        c = cls()
        c.workspace = workspace
        c.docs_dir = os.path.join(workspace, "docs")
        c.flutter_lib = os.path.join(workspace, "flutter_app", "lib")
        c.server_dir = os.path.join(workspace, "server")
        return c


# ═══════════════════════════════════════════════
# 结果模型
# ═══════════════════════════════════════════════

class Certainty:
    CERTAIN = "CERTAIN"
    LIKELY = "LIKELY"
    SUSPICIOUS = "SUSPICIOUS"


@dataclass
class Finding:
    certainty: str       # CERTAIN / LIKELY / SUSPICIOUS
    issue: str           # 问题简述
    source: str          # 设计文档来源（文件:行）
    path: str            # 涉及的代码路径
    evidence: str        # 证据链摘要
    detail: str = ""     # 详细日志

    def __str__(self):
        return f"{self.certainty} | {self.issue} | {self.source} | {self.path} | {self.evidence}"


# ═══════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════

def log(msg: str):
    print(f"[AUDIT] {msg}")


def path_exists(p: str) -> bool:
    return os.path.exists(p)


def read_file(p: str) -> str:
    try:
        with open(p, "r", encoding="utf-8") as f:
            return f.read()
    except:
        return ""


def glob_files(root: str, pattern: str) -> list:
    """简易 glob：返回匹配 pattern 的文件的相对路径列表"""
    results = []
    pattern = pattern.replace("*", "")
    for dirpath, dirnames, filenames in os.walk(root):
        for fn in filenames:
            if pattern in fn:
                full = os.path.join(dirpath, fn)
                results.append(os.path.relpath(full, root))
    return sorted(results)


def grep(pattern: str, root: str, file_glob: str = "") -> list:
    """简易 grep：返回匹配的行 (file, line, content)"""
    results = []
    for dirpath, dirnames, filenames in os.walk(root):
        for fn in filenames:
            if file_glob and file_glob not in fn:
                continue
            fp = os.path.join(dirpath, fn)
            try:
                with open(fp, "r", encoding="utf-8") as f:
                    for i, line in enumerate(f, 1):
                        if re.search(pattern, line):
                            rel = os.path.relpath(fp, root)
                            results.append((rel, i, line.strip()))
            except:
                pass
    return results


# ═══════════════════════════════════════════════
# 检查模块 1: 文件/目录存在性
# ═══════════════════════════════════════════════

def check_directory_exists(cfg: Config) -> list[Finding]:
    """全覆盖矩阵中要求的目录是否存在于磁盘上"""
    findings = []
    
    checks = [
        ("flutter_app/assets/questions/images/", 
         "05-Flutter/图片路由规范.md §一 L14",
         "题库配图目录，设计文档明确要求存在"),
        ("flutter_app/assets/db/",
         "02-数据/构建脚本设计.md §构建产物",
         "捆绑数据库目录，构建脚本产出"),
    ]
    
    for rel_path, source, desc in checks:
        full = os.path.join(cfg.workspace, rel_path)
        exists = path_exists(full)
        evidence = f"Test-Path('{rel_path}') → {exists}"
        findings.append(Finding(
            certainty=Certainty.CERTAIN if not exists else Certainty.LIKELY,
            issue=f"{'❌ 缺失' if not exists else '✅ 存在'}: {desc} ({rel_path})",
            source=source,
            path=rel_path,
            evidence=evidence,
            detail=evidence
        ))
    return findings


# ═══════════════════════════════════════════════
# 检查模块 2: HTML → Flutter 页面覆盖
# ═══════════════════════════════════════════════

def check_html_to_flutter_pages(cfg: Config) -> list[Finding]:
    """从 HTML 原型出发，检查每个 .html 是否有对应 Flutter _page.dart"""
    findings = []
    
    html_dir = os.path.join(cfg.docs_dir, "04-UI", "html")
    pages_dir = os.path.join(cfg.flutter_lib, "pages")
    
    if not path_exists(html_dir):
        return [Finding(Certainty.LIKELY, "HTML 原型目录不存在", "C4", html_dir, "")]
    
    html_files = [f for f in os.listdir(html_dir) if f.endswith(".html")]
    # 排除 solve-pages 子目录下的文件，那些按子文件夹处理
    html_files = [f for f in html_files if not f.startswith("solve-")]
    
    # 收集所有 Flutter page 文件
    flutter_pages = set()
    for dirpath, dirnames, filenames in os.walk(pages_dir):
        for fn in filenames:
            if fn.endswith("_page.dart"):
                flutter_pages.add(fn)
    
    # HTML 文件名 → 可能的 Flutter 页名映射
    html_to_flutter = {
        "index.html": "index_page.dart",
        "login.html": "login_page.dart",
        "register.html": "register_page.dart",
        "recommend.html": "recommend_page.dart",
        "profile.html": "profile_page.dart",
        "profile_edit.html": "profile_edit_page.dart",
        "about.html": "about_page.dart",
        "achievement.html": "achievement_page.dart",
        "level_detail.html": "level_detail_page.dart",
        "points.html": "points_page.dart",
        "question_history.html": "question_history_page.dart",
        "preference_list.html": "preference_list_page.dart",
        "preference_edit.html": "preference_edit_page.dart",
        "preference_welcome.html": "preference_welcome_page.dart",
        "statistics.html": "statistics_page.dart",
        "homework_list.html": "homework_list_page.dart",
        "homework_detail.html": "homework_detail_page.dart",
        "sync_queue.html": "sync_queue_page.dart",
        "exam.html": "exam_home_page.dart",
        "paper_auto.html": "exam_auto_page.dart",
        "paper_pick.html": "exam_pick_page.dart",
        "paper_explore.html": "exam_explore_page.dart",
        "paper_favorites.html": "exam_favorites_page.dart",
        "paper_history.html": "exam_history_page.dart",
        "paper_quicklook.html": "exam_quicklook_page.dart",
        "paper_quicklook_other.html": "exam_quicklook_other_page.dart",
        "answer_sheet.html": "answer_sheet_page.dart",
        "lecture_courses.html": "lecture_courses_page.dart",
        "lecture_chapters.html": "lecture_chapters_page.dart",
        "lecture_content.html": "lecture_content_page.dart",
        "debug.html": None,  # dev-only，合理缺失
    }
    
    for html_fn in sorted(html_files):
        expected_flutter = html_to_flutter.get(html_fn)
        if expected_flutter is None:
            continue  # 已知可忽略
        
        exists = expected_flutter in flutter_pages
        findings.append(Finding(
            certainty=Certainty.CERTAIN if not exists else Certainty.LIKELY,
            issue=f"{'❌ 缺失' if not exists else '✅ 存在'}: {html_fn} → {expected_flutter}",
            source=f"C4: {html_fn}",
            path=f"flutter_app/lib/pages/{expected_flutter}",
            evidence=f"Listing .html files from docs/04-UI/html/ (total={len(html_files)}), checking each against flutter_app/lib/pages/",
            detail=f"Flutter pages found: {len(flutter_pages)} files"
        ))
    
    return findings


# ═══════════════════════════════════════════════
# 检查模块 2B: HTML 内 UI 元素提取（R0 扩展 — 对关键页面做区块级清单）
# ═══════════════════════════════════════════════

# 关键页面: 从中提取语义区块，供人工比对 Flutter 实现
KEY_HTML_PAGES = {
    "index.html": [
        ("欢迎语卡片", "card", "欢迎/每天一句"),
        ("待办作业入口", "a[href*=homework]", "📝 待办作业"),
        ("讲义入口", "a[href*=lecture]", "📖 讲义"),
        ("签到行(按钮+连续天数)", "button+span", "🔥 签到"),
        ("签到进度条(7天奖励阶梯)", "progress bar", "第1天→第7天"),
        ("任务列表(4项+积分)", "task-item", "✅/⬜ + 积分"),
        ("等级进度+今日积分", "div", "🏅 Lv.X 今日积分"),
        ("Toast签到反馈", "toast-container", "🔥 签到成功"),
        ("底栏导航(首页/推荐/组卷/我的)", "nav.bottom-nav", "4个Tab"),
    ],
    "login.html": [
        ("品牌标识", "text", "🐙 章鱼智学"),
        ("用户名输入框", "input", "用户名"),
        ("密码输入框", "input[type=password]", "密码"),
        ("登录按钮", "button", "登录"),
        ("注册链接", "a", "注册"),
    ],
    "profile.html": [
        ("个人信息卡片(头像/姓名/学号)", "card", "头像+编辑"),
        ("学习偏好入口", "a[href*=preference]", "📋 学习偏好"),
        ("学习统计入口", "a[href*=statistics]", "📊 学习统计"),
        ("做题历史入口", "a[href*=history]", "📝 做题历史"),
        ("成就入口", "a[href*=achievement]", "🏆 成就"),
        ("等级入口", "a[href*=level]", "🏅 等级"),
        ("积分流水入口", "a[href*=points]", "💰 积分流水"),
        ("同步状态入口", "a[href*=sync]", "📤 同步状态"),
        ("关于入口", "a[href*=about]", "ℹ️ 关于"),
        ("退出登录", "button/logout", "退出登录(红色)"),
        ("底栏导航(首页/推荐/组卷/我的)", "nav.bottom-nav", "4个Tab"),
    ],
    "exam.html": [
        ("标题", "h1", "组卷"),
        ("智能组卷卡片", "card", "🤖 智能组卷"),
        ("自主选题卡片", "card", "🖐 自主选题"),
        ("我的组卷入ロ", "a", "📋 我的组卷"),
        ("发现组卷入ロ", "a", "🌐 发现组卷"),
        ("我的收藏入口", "a", "🔖 我的收藏"),
    ],
    "statistics.html": [
        ("时间范围切换(pills)", "sort-pill", "5个时间选项"),
        ("概览卡片(4项)", "card", "做题/正确率/连续/活跃"),
        ("做题热力图", "chart", "Heatmap"),
        ("正确率趋势", "chart", "折线图"),
        ("积分累计趋势", "chart", "折线图"),
        ("题型分布", "chart", "环形图"),
    ],
    "solve-choice.html": [
        ("题目元信息(题号/题型)", "meta", "第X题·[选择]"),
        ("作答次数选择器", "attempt-selector", "多存档"),
        ("回顾模式banner", "review-banner", "回顾模式"),
        ("题干(LaTeX)", "content", "MdLatexBody"),
        ("选项网格(A/B/C/D)", "options", "4选项"),
        ("提交按钮/冷却", "button", "提交+冷却"),
        ("解析/结果区", "result", "正确/错误+解析"),
        ("已完成+下一题/评分", "done", "下一题/⭐评分"),
    ],
    "solve-rate.html": [
        ("难度评分(10星+算法分)", "star-rating", "难度对比"),
        ("计算量评分(10星+算法分)", "star-rating", "计算量对比"),
        ("优雅度评分(10星)", "star-rating", "优雅度"),
        ("提交按钮", "button", "提交评分"),
        ("积分奖励提示", "text", "+0.3 赠送积分"),
    ],
}


def check_html_element_inventory(cfg: Config) -> list[Finding]:
    """对关键 HTML 页面提取 UI 元素清单（R0 输出），供人工逐项 vs Flutter 验证"""
    findings = []
    html_dir = os.path.join(cfg.docs_dir, "04-UI", "html")
    solve_dir = os.path.join(html_dir, "solve-pages")

    for page_name, elements in KEY_HTML_PAGES.items():
        # 找到 HTML 文件
        html_path = os.path.join(html_dir, page_name)
        if not os.path.exists(html_path):
            html_path = os.path.join(solve_dir, page_name)
        if not os.path.exists(html_path):
            continue

        # 输出该页面的完整 UI 元素清单（由 KEY_HTML_PAGES 定义，来源是直接阅读 HTML）
        # 每条为 LIKELY 级别，供人工比对 Flutter 实现
        total = len(elements)
        for i, (elem_name, elem_type, hint) in enumerate(elements, 1):
            findings.append(Finding(
                certainty=Certainty.LIKELY,
                issue=f"[{page_name}] 元素 {i}/{total}: {elem_name}",
                source=f"C4: {page_name} §{elem_type}",
                path=f"docs/04-UI/html/{page_name}",
                evidence=f"HTML 原型定义了此元素（{hint}），需人工确认 Flutter 实现",
                detail=f"Type: {elem_type}"
            ))

    return findings


# ═══════════════════════════════════════════════
# 检查模块 3: pubspec.yaml 资产声明验证
# ═══════════════════════════════════════════════

def check_pubspec_assets(cfg: Config) -> list[Finding]:
    """验证 lib/ 下引用的 asset 路径都在 pubspec.yaml 中声明"""
    findings = []
    
    pubspec_path = os.path.join(cfg.workspace, "flutter_app", "pubspec.yaml")
    pubspec_content = read_file(pubspec_path)
    
    if not pubspec_content:
        return [Finding(Certainty.CERTAIN, "pubspec.yaml 不存在", "B*", pubspec_path, "")]
    
    # 提取 pubspec.yaml 中声明的 assets
    declared_assets = set()
    in_assets = False
    for line in pubspec_content.split("\n"):
        if line.strip().startswith("assets:"):
            in_assets = True
            continue
        if in_assets:
            m = re.match(r"\s*-\s*(.+)$", line)
            if m:
                asset_path = m.group(1).strip()
                declared_assets.add(asset_path)
                # 如果是目录（以 / 结尾），所有子文件也算
                if asset_path.endswith("/"):
                    declared_assets.add(asset_path)
            elif line.strip() and not line.strip().startswith("#") and not line.strip().startswith("- "):
                in_assets = False
    
    # 提取 lib/ 下所有 rootBundle.load / AssetImage 引用的路径
    referenced_paths = set()
    for rel, line_no, content in grep(r"(rootBundle\.load|AssetImage)\(", cfg.flutter_lib):
        m = re.search(r"['\"]assets/([^'\"]+)['\"]", content)
        if m:
            ref = "assets/" + m.group(1)
            # 转为目录形式
            referenced_paths.add((ref, rel, line_no))
    
    # 检查：每个引用的路径是否被声明（或其父目录被声明）
    for ref, file_path, line_no in sorted(referenced_paths):
        declared = False
        for declared_asset in declared_assets:
            if ref == declared_asset:
                declared = True
                break
            # 如果声明的是目录 assets/db/，它覆盖 assets/db/assets.db
            if declared_asset.endswith("/") and ref.startswith(declared_asset):
                declared = True
                break
        
        findings.append(Finding(
            certainty=Certainty.CERTAIN if not declared else Certainty.LIKELY,
            issue=f"{'❌ 未声明' if not declared else '✅ 已声明'}: {ref} (引用自 {file_path}:{line_no})",
            source="B*: pubspec.yaml asset declarations",
            path=file_path,
            evidence=f"rootBundle.load('{ref}') found in {file_path}:{line_no}",
            detail=f"Declared assets: {declared_assets}"
        ))
    
    # 额外检查：设计文档要求的资产目录是否在 pubspec.yaml 中声明
    required_assets = [
        ("assets/questions/images/", "05-Flutter/图片路由规范.md §一 L14"),
        ("assets/db/", "02-数据/构建脚本设计.md §构建产物"),
    ]
    for req_path, source in required_assets:
        declared = any(req_path.startswith(a) or a == req_path for a in declared_assets)
        if not declared:
            findings.append(Finding(
                certainty=Certainty.CERTAIN if path_exists(os.path.join(cfg.workspace, "flutter_app", req_path)) else Certainty.LIKELY,
                issue=f"{'⚠️ 未声明' if not declared else '✅ 已声明'}: {req_path} 在设计文档中要求但 pubspec.yaml 未声明",
                source=source,
                path="flutter_app/pubspec.yaml",
                evidence=f"Design doc requires asset path, pubspec.yaml assets: {declared_assets}",
                detail=f"Required by {source}"
            ))
    
    return findings


# ═══════════════════════════════════════════════
# 检查模块 4: 设计文档"待完成"标记提取
# ═══════════════════════════════════════════════

def check_design_doc_pending_markers(cfg: Config) -> list[Finding]:
    """提取所有设计文档中的"后续待完成/待定/预留/TODO"标记"""
    findings = []
    
    patterns = [
        r"后续待完成",
        r"(?<!// )(?<!<!-- )待定(?![^。]*[。！？])",
        r"预留",
        r"未落地",
        r"未实际创建",
        r"设计阶段[^的]",
    ]
    compiled = [re.compile(p) for p in patterns]
    
    # 只扫描关键的几份设计文档
    doc_files = [
        "02-数据/数据库结构设计.md",
        "02-数据/更新机制.md",
        "02-数据/构建脚本设计.md",
        "03-服务端/API设计.md",
        "03-服务端/PDF方案设计.md",
        "04-UI/页面设计说明.md",
        "05-Flutter/图片路由规范.md",
        "05-Flutter/同步引擎设计.md",
        "05-Flutter/数据访问层设计.md",
        "06-教师端/教师端功能边界.md",
        "备份方案.md",
        "测试策略.md",
    ]
    
    for doc in doc_files:
        doc_path = os.path.join(cfg.docs_dir, doc)
        if not path_exists(doc_path):
            continue
        content = read_file(doc_path)
        for i, line in enumerate(content.split("\n"), 1):
            for pat in compiled:
                if pat.search(line) and not line.strip().startswith("#") and not line.strip().startswith(">") and "auto-audit: accepted-deferred" not in line:
                    findings.append(Finding(
                        certainty=Certainty.CERTAIN,
                        issue=f"⬜ 延期标记: {line.strip()[:80]}",
                        source=f"{doc}:L{i}",
                        path=doc,
                        evidence=f"Design doc states unfinished status at line {i}",
                        detail=f"Full line: {line.strip()}"
                    ))
                    break  # 一行只报一次
    
    return findings


# ═══════════════════════════════════════════════
# 检查模块 5: 测试文件覆盖率
# ═══════════════════════════════════════════════

def check_test_coverage(cfg: Config) -> list[Finding]:
    """检查测试文件是否覆盖了所有页面"""
    findings = []
    
    test_dir = os.path.join(cfg.workspace, "flutter_app", "test", "pages")
    if not path_exists(test_dir):
        return [Finding(Certainty.LIKELY, "Flutter 测试目录不存在", "C12", test_dir, "")]
    
    # 收集所有测试文件
    test_files = set()
    for dirpath, dirnames, filenames in os.walk(test_dir):
        for fn in filenames:
            if fn.endswith("_test.dart"):
                test_files.add(fn)
    
    # 检查每个 page 是否有对应的 test
    pages_dir = os.path.join(cfg.flutter_lib, "pages")
    page_files = set()
    for dirpath, dirnames, filenames in os.walk(pages_dir):
        for fn in filenames:
            if fn.endswith("_page.dart"):
                page_files.add(fn)
    
    for page_fn in sorted(page_files):
        # 对应的测试文件命名: page_name_page.dart → page_name_page_test.dart
        test_fn = page_fn.replace("_page.dart", "_page_test.dart")
        exists = test_fn in test_files
        
        if not exists:
            findings.append(Finding(
                certainty=Certainty.CERTAIN,
                issue=f"❌ 缺少测试: {page_fn} → 期望 {test_fn}",
                source="C12: 测试策略.md §UI层测试要求",
                path=f"flutter_app/test/pages/{test_fn}",
                evidence=f"Page exists at flutter_app/lib/pages/, but no test file at test/pages/",
                detail=f"Test files found: {len(test_files)}"
            ))
    
    return findings


# ═══════════════════════════════════════════════
# 检查模块 6: 代码 stub/TODO 扫描
# ═══════════════════════════════════════════════

def check_stubs_and_todos(cfg: Config) -> list[Finding]:
    """扫描代码中的 stub 模式"""
    findings = []
    
    stub_patterns = [
        (r"UnimplementedError|Unimplemented", "UnimplementedError 抛出"),
        (r"return \s*\[\s*\]", "stub: return []"),
        (r"return \s*0\s*;", "stub: return 0（可能）"),
        (r"return \s*false\s*;", "stub: return false（可能）"),
        (r"//\s*TODO[^)]", "TODO 注释"),
        (r"//\s*v1\s+方案", "v1 方案标注"),
        (r"极简版本|临时方案|后续再做|待接入", "临时/简化标注"),
    ]
    
    # 只扫描关键目录
    scan_dirs = [
        (cfg.flutter_lib, "flutter_app/lib/"),
    ]
    
    if path_exists(cfg.server_dir):
        scan_dirs.append((cfg.server_dir, "server/"))
    
    for root, prefix in scan_dirs:
        for pat, label in stub_patterns:
            results = grep(pat, root, ".dart")
            if results:
                # 只报告前 5 条
                for rel, line_no, content in results[:5]:
                    findings.append(Finding(
                        certainty=Certainty.SUSPICIOUS,
                        issue=f"{label}: {content[:60]}",
                        source="④ Anti-Half-Assing",
                        path=f"{prefix}{rel}:L{line_no}",
                        evidence=f"Found {len(results)} matches total for pattern '{label}'",
                        detail=f"Total matches: {len(results)}"
                    ))
    
    return findings


# ═══════════════════════════════════════════════
# 检查模块 7: 导航架构
# ═══════════════════════════════════════════════

def check_navigation_architecture(cfg: Config) -> list[Finding]:
    """提取 HTML 底栏 Tab 结构，对比 Flutter MainShell"""
    findings = []
    
    html_dir = os.path.join(cfg.docs_dir, "04-UI", "html")
    index_html = os.path.join(html_dir, "index.html")
    
    if not path_exists(index_html):
        return []
    
    content = read_file(index_html)
    
    # 提取 <nav class="bottom-nav"> 中的 Tab
    nav_match = re.search(r'<nav class="bottom-nav">(.*?)</nav>', content, re.DOTALL)
    html_tabs = []
    if nav_match:
        for a_tag in re.finditer(r'<a href="([^"]+)"[^>]*>\s*<span[^>]*>([^<]+)</span>', nav_match.group(1)):
            href = a_tag.group(1)
            label = a_tag.group(2)
            html_tabs.append((href, label))
    
    # 提取 Flutter MainShell 中的 Tab
    main_shell_path = os.path.join(cfg.flutter_lib, "pages", "main_shell.dart")
    if path_exists(main_shell_path):
        ms_content = read_file(main_shell_path)
        # 找 BottomNavigationBar items
        flutter_tabs = []
        for m in re.finditer(r"BottomNavigationBarItem\(.*?label:\s*'([^']+)',?", ms_content, re.DOTALL):
            flutter_tabs.append(m.group(1))
        
        if html_tabs and flutter_tabs:
            html_labels = [t[1] for t in html_tabs]
            if html_labels != flutter_tabs:
                findings.append(Finding(
                    certainty=Certainty.CERTAIN,
                    issue=f"❌ 底栏导航 Tab 不同: HTML={html_labels} vs Flutter={flutter_tabs}",
                    source="C6: 页面导航.md | C4: index.html <nav>",
                    path="flutter_app/lib/pages/main_shell.dart",
                    evidence=f"Extracted from HTML: {html_tabs}",
                    detail=f"Flutter tabs: {flutter_tabs}"
                ))
            else:
                findings.append(Finding(
                    certainty=Certainty.LIKELY,
                    issue=f"✅ 底栏导航 Tab 一致: {flutter_tabs}",
                    source="C6: 页面导航.md",
                    path="flutter_app/lib/pages/main_shell.dart",
                    evidence="HTML bottom-nav matches Flutter BottomNavigationBar items",
                    detail=""
                ))
    
    return findings


# ═══════════════════════════════════════════════
# ═══════════════════════════════════════════════
# 报告生成
# ═══════════════════════════════════════════════

def generate_report(findings: list[Finding], output_path: str = ""):
    """生成报告"""
    certain = [f for f in findings if f.certainty == Certainty.CERTAIN and ("❌" in f.issue or "⬜" in f.issue)]
    likely = [f for f in findings if f.certainty == Certainty.LIKELY and ("❌" in f.issue or "⚠" in f.issue)]
    suspicious = [f for f in findings if f.certainty == Certainty.SUSPICIOUS]
    passed = [f for f in findings if "✅" in f.issue]
    
    report = []
    report.append("=" * 70)
    report.append("章鱼智学 · 自动化审计报告")
    report.append("=" * 70)
    report.append("")
    
    report.append(f"总计检查: {len(findings)} 项")
    report.append(f"  CERTAIN ❌ 问题: {len(certain)}")
    report.append(f"  LIKELY ⚠️  告警: {len(likely)}")
    report.append(f"  SUSPICIOUS 可疑: {len(suspicious)}")
    report.append(f"  ✅ 通过: {len(passed)}")
    report.append("")
    
    if certain:
        report.append("─" * 70)
        report.append("🔴 CERTAIN 问题（无需人工审核，直接采纳）")
        report.append("─" * 70)
        for f in certain:
            report.append(f"  ❌ {f.issue}")
            report.append(f"     来源: {f.source}")
            report.append(f"     路径: {f.path}")
            report.append(f"     证据: {f.evidence}")
            report.append("")
    
    if likely:
        report.append("─" * 70)
        report.append("🟡 LIKELY 告警（需人工审核 3 分钟/条）")
        report.append("─" * 70)
        for f in likely:
            report.append(f"  ⚠️  {f.issue}")
            report.append(f"     来源: {f.source}")
            report.append(f"     路径: {f.path}")
            report.append(f"     证据: {f.evidence}")
            report.append("")
    
    if suspicious:
        report.append("─" * 70)
        report.append("🔍 SUSPICIOUS 可疑（需人工审核 3 分钟/条）")
        report.append("─" * 70)
        for f in suspicious:
            report.append(f"  ❓ {f.issue}")
            report.append(f"     路径: {f.path}")
            report.append(f"     证据: {f.evidence}")
            report.append("")
    
    report_str = "\n".join(report)
    
    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report_str)
        log(f"\n报告已写入: {output_path}")
    
    print(report_str)
    return report_str


# ═══════════════════════════════════════════════
# 审计类型 → 模块映射
# ═══════════════════════════════════════════════

TYPE_MODULES = {
    "A": [1, 3, 4, 5],           # 服务端
    "B": [1, 3, 4, 5, 6],        # Flutter 数据层
    "C": [1, 2, 4, 5, 6, 7],     # Flutter UI
    "D": [1, 3, 4, 5],           # 教师端
    "E": [1, 3, 4],              # 部署
    "F": [1, 4],                 # 数据迁移
    "G": [4, 6],                 # 全项目横切
}

MODULE_NAMES = {
    1: "目录/文件存在性",
    2: "HTML→Flutter 页面覆盖",
    3: "pubspec.yaml 资产声明",
    4: "设计文档待完成标记",
    5: "测试文件覆盖率",
    6: "stub/TODO 扫描",
    7: "导航架构",
}

def run_modules(cfg: Config, modules: list[int]) -> list[Finding]:
    """按模块列表选择性执行检查"""
    all_findings = []

    if 1 in modules:
        log("[模块 1/7] 目录/文件存在性...")
        all_findings.extend(check_directory_exists(cfg))
    if 2 in modules:
        log("[模块 2/7] HTML→Flutter 页面覆盖 + 元素清单提取...")
        all_findings.extend(check_html_to_flutter_pages(cfg))
        all_findings.extend(check_html_element_inventory(cfg))
    if 3 in modules:
        log("[模块 3/7] pubspec.yaml 资产声明...")
        all_findings.extend(check_pubspec_assets(cfg))
    if 4 in modules:
        log("[模块 4/7] 设计文档待完成标记...")
        all_findings.extend(check_design_doc_pending_markers(cfg))
    if 5 in modules:
        log("[模块 5/7] 测试文件覆盖率...")
        all_findings.extend(check_test_coverage(cfg))
    if 6 in modules:
        log("[模块 6/7] stub/TODO 扫描...")
        all_findings.extend(check_stubs_and_todos(cfg))
    if 7 in modules:
        log("[模块 7/7] 导航架构...")
        all_findings.extend(check_navigation_architecture(cfg))

    return all_findings


def main():
    import argparse
    parser = argparse.ArgumentParser(description="章鱼智学自动化审计引擎")
    parser.add_argument("workspace", nargs="?", help="项目根目录路径")
    parser.add_argument("--type", "-t", choices=list(TYPE_MODULES.keys()) + [""],
                        default="", help="审计类型 A-G（不指定则全量）")
    args = parser.parse_args()

    if args.workspace:
        workspace = os.path.abspath(args.workspace)
    else:
        workspace = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        print(f"用法: python audit_engine.py <workspace_path> [--type A|B|C|D|E|F|G]")
        print(f"默认使用: {workspace}")

    if not os.path.exists(workspace):
        print(f"错误: 目录不存在: {workspace}")
        sys.exit(1)

    cfg = Config.detect(workspace)

    if args.type:
        modules = TYPE_MODULES[args.type]
        log(f"审计类型: {args.type} → 模块 {modules}")
        log(f"模块明细: {[f'{m}-{MODULE_NAMES[m]}' for m in modules]}")
        findings = run_modules(cfg, modules)
    else:
        log("审计类型: 全量 (A-G 全部模块)")
        findings = run_modules(cfg, sorted(MODULE_NAMES.keys()))

    report_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "audit_report_latest.txt")
    generate_report(findings, report_path)


if __name__ == "__main__":
    main()
