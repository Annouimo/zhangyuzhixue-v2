"""
批量视觉分析 — 并行 vision_analyze 截图，生成 V1-V4 检查结果。

用法:
    python vision_report/batch_analyze.py <screenshots_dir>

输出:
    JSON 格式的 V1-V4 检查结果，每页一条
"""
import sys
import os
import json
import glob
from collections import defaultdict


# 每页的预期检查内容（来自 HTML 原型）
PAGE_EXPECTATIONS = {
    "index": [
        ("V1_layout", "检查：欢迎语卡片、签到行、待办作业入口、底部导航 Tab 是否完整可见"),
        ("V2_data", "提取数值：签到天数、待办作业计数、等级数字"),
        ("V4_empty", "检查：数据为空时是否有占位符文案"),
    ],
    "exam_home": [
        ("V1_layout", "检查：智能组卷、自主选题、发现组卷、收藏 四个入口卡片是否可见"),
        ("V4_empty", "检查：各组卷列表为空时是否有占位符"),
    ],
    "exam_pick": [
        ("V1_layout", "检查：筛选面板（年级/地区/题型/难度）和底部确认按钮是否可见"),
        ("V4_empty", "筛选结果为空时是否有占位符"),
    ],
    "profile": [
        ("V1_layout", "检查：个人信息卡片、各入口列表（学习偏好/统计/成就/等级/积分/做题历史/同步/关于/退出登录）"),
        ("V2_data", "提取数值：姓名、学号"),
    ],
    "solve_choice": [
        ("V1_layout", "检查：题干（LaTeX）、选项网格、提交按钮、冷却倒计时"),
        ("V2_data", "提取：题号、选项文本"),
        ("V4_empty", "无数据时占位符"),
    ],
    "lecture_courses": [
        ("V1_layout", "检查：课程卡片列表"),
        ("V4_empty", "课程为空时占位符"),
    ],
    "homework_list": [
        ("V1_layout", "检查：作业列表项、待办标记"),
        ("V2_data", "提取：作业计数"),
    ],
    "achievement": [
        ("V1_layout", "检查：成就列表、解锁状态"),
        ("V2_data", "提取：已解锁/总数"),
    ],
}


def analyze_batch(screenshots_dir: str):
    """批量分析截图（通过 delegate_task 分发）"""
    all_pngs = sorted(glob.glob(os.path.join(screenshots_dir, "*.png")))
    print(f"共 {len(all_pngs)} 张截图待分析")

    # 按页面分组
    by_page = defaultdict(list)
    for fp in all_pngs:
        fname = os.path.basename(fp)
        page = fname.split("_")[0]
        by_page[page].append(fp)

    results = {}
    for page, files in sorted(by_page.items()):
        expectations = PAGE_EXPECTATIONS.get(page, [("V1_layout", "检查页面布局完整性")])
        results[page] = {
            "screenshots": files,
            "checks": [{"dim": dim, "prompt": prompt} for dim, prompt in expectations],
        }

    # 输出供 merge_reports.py 使用
    out_path = os.path.join(screenshots_dir, "..", "_vision_tasks.json")
    with open(out_path, "w") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(f"分析任务已输出: {out_path}")
    return out_path


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python batch_analyze.py <screenshots_dir>")
        sys.exit(1)
    analyze_batch(sys.argv[1])
