"""
自动走查主流程 — pyautogui 遍历 35 页，截图 + 触发 NDJSON。

用法:
    python nav_engine/walker.py D:\\Hermes\\zhangyuzhixue_app_v2

前置:
    flutter run --dart-define=AUDIT_MODE=true 已在终端运行
    桌面不锁屏，窗口可见
"""
import sys
import time
import os

import pyautogui

# 确保目录在 path 中
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screenshot import init as init_ss, find_window, ensure_foreground, capture
from registry import REGISTRY, NavTarget


# 底部 Tab 的标准坐标（在 390x844 窗口中的相对坐标）
# 四个 Tab: 首页/推荐/组卷/我的
BOTTOM_TAB_X = [50, 145, 240, 335]
BOTTOM_TAB_Y = 810


def click_tab(index: int):
    """点击底部 Tab"""
    x, y = BOTTOM_TAB_X[index], BOTTOM_TAB_Y[index]
    pyautogui.click(x, y)
    time.sleep(0.8)


def click_text(text: str):
    """尝试通过 pyautogui.locateOnScreen 点击文字（备用方案：使用坐标猜测）"""
    # 简化实现：对常见按钮使用固定坐标偏移
    # 正式使用时应接入 OCR 定位或 OpenCV 模板匹配
    pyautogui.click(195, 400)  # 中间点，等待实际定位实现
    time.sleep(0.5)


def walk_target(tgt: NavTarget, hwnd: int):
    """执行单个页面的导航和截图"""
    results = []
    for action, *args in tgt.nav_seq:
        if action == "click_bottom_tab":
            click_tab(args[0])
        elif action == "click_text":
            click_text(args[0])
        elif action == "wait":
            time.sleep(args[0])
        elif action == "screenshot":
            fpath = capture(hwnd, tgt.name, args[0])
            results.append(fpath)
            print(f"  [截图] {tgt.name}/{args[0]} → {fpath}")
    return results


def main(workspace: str):
    """主走查流程"""
    # 1. 初始化截图目录
    ss_dir = init_ss(workspace)
    print(f"截图目录: {ss_dir}")

    # 2. 定位窗口
    hwnd = find_window()
    ensure_foreground(hwnd)
    print(f"窗口句柄: {hwnd}")

    # 3. 等待 app 就绪
    time.sleep(2)

    # 4. 逐组走查
    all_screenshots = []
    current_group = None
    for tgt in REGISTRY:
        if tgt.group != current_group:
            current_group = tgt.group
            print(f"\n=== Group {current_group}: {tgt.label} ===")

        try:
            screenshots = walk_target(tgt, hwnd)
            all_screenshots.extend(screenshots)
        except Exception as e:
            print(f"  ⚠️ 导航到 {tgt.name} 失败: {e}")
            # fail-fast: 一个页面失败，继续下一组
            continue

    print(f"\n✅ 走查完成。共 {len(all_screenshots)} 张截图。")
    print(f"NDJSON 日志已由 AuditLogger 写入 %TEMP%/zhangyuzhixue_audit.ndjson")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python walker.py <workspace_path>")
        sys.exit(1)
    main(sys.argv[1])
