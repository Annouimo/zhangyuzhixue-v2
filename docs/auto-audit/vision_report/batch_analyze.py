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
    # 更多页面... 在运行时根据截图文件名自动匹配
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
