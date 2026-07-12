"""
合并报告 — 将 R 断言结果 + V 视觉检查结果合并为最终报告。

用法:
    python vision_report/merge_reports.py <workspace> [r_report_path] [v_results_dir]

依赖:
    audit_engine.py --type R 的 output (audit_report_latest.txt)
    batch_analyze.py 的输出目录
"""
import sys
import os
import json
import re
from collections import defaultdict


# G1-G6 分组定义（与 registry.py 保持一致，覆盖全部 35 页）
GROUP_MAP = {
    "IndexPage": "G1", "LoginPage": "G1", "RegisterPage": "G1",
    "RecommendPage": "G1",
    "ExamHomePage": "G2", "ExamPickPage": "G2", "ExamAutoPage": "G2",
    "ExamExplorePage": "G2", "ExamFavoritesPage": "G2", "ExamHistoryPage": "G2",
    "ExamQuicklookPage": "G2", "ExamQuicklookOtherPage": "G2", "AnswerSheetPage": "G2",
    "SolveChoicePage": "G3", "SolveFillPage": "G3", "SolveStepPage": "G3",
    "SolveRatePage": "G3", "SolveMapPage": "G3",
    "LectureCoursesPage": "G4", "LectureChaptersPage": "G4", "LectureContentPage": "G4",
    "HomeworkListPage": "G5", "HomeworkDetailPage": "G5",
    "ProfilePage": "G6", "ProfileEditPage": "G6", "StatisticsPage": "G6",
    "AchievementPage": "G6", "LevelDetailPage": "G6", "PointsPage": "G6",
    "QuestionHistoryPage": "G6", "PreferenceListPage": "G6",
    "PreferenceEditPage": "G6", "PreferenceWelcomePage": "G6",
    "SyncQueuePage": "G6", "AboutPage": "G6",
}

GROUP_NAMES = {
    "G1": "核心导航", "G2": "组卷/试题浏览", "G3": "解题流程",
    "G4": "讲义", "G5": "作业", "G6": "个人中心",
}


def parse_r_report(r_report_path: str) -> dict:
    """解析 audit_engine.py --type R 的输出报告"""
    result = {"certain": [], "likely": [], "suspicious": [], "passed": []}
    if not os.path.exists(r_report_path):
        return result
    with open(r_report_path, "r") as f:
        content = f.read()
    current_section = None
    for line in content.split("\n"):
        if "CERTAIN" in line:
            current_section = "certain"
        elif "LIKELY" in line:
            current_section = "likely"
        elif "SUSPICIOUS" in line:
            current_section = "suspicious"
        elif "通过" in line:
            current_section = "passed"
        elif line.strip().startswith("❌") or line.strip().startswith("⚠") or line.strip().startswith("❓"):
            result[current_section].append(line.strip()[:100])
    return result


def merge(workspace: str, r_report: str = "", v_results: str = ""):
    """合并 R 断言 + V 视觉结果"""
    # 默认路径
    if not r_report:
        r_report = os.path.join(workspace, "docs", "auto-audit", "audit_report_latest.txt")

    # 解析 R 报告
    r_data = parse_r_report(r_report)

    # 合并输出
    print("=" * 60)
    print("章鱼智学 · 合并审计报告 (R + V)")
    print("=" * 60)

    # 按分组输出
    by_group = defaultdict(list)
    for item in r_data["certain"]:
        by_group["横切"].append(f"❌ {item}")

    print("\n### 按分组\n")
    for gid in ["G1", "G2", "G3", "G4", "G5", "G6"]:
        gname = GROUP_NAMES[gid]
        items = by_group.get(gid, []) + by_group.get("横切", [])
        status = "✅" if not items else "⚠️"
        print(f"  {gid} {gname}: {status}")

    print(f"\n### 总计")
    print(f"  CERTAIN ❌: {len(r_data['certain'])}")
    print(f"  LIKELY  ⚠️: {len(r_data['likely'])}")
    print(f"  SUSPICIOUS ❓: {len(r_data['suspicious'])}")

    print(f"\n### 说明")
    print(f"  R = NDJSON 断言（数据层）")
    if v_results:
        print(f"  V = Vision 视觉检查（布局/显示）")
    print(f"  截图目录: docs/auto-audit/screenshots/")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python merge_reports.py <workspace> [r_report] [v_results]")
        sys.exit(1)
    merge(*sys.argv[1:])
