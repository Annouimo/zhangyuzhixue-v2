"""
自动走查主流程 — pyautogui 遍历 34 页，截图 + 触发 NDJSON。

用法:
    python nav_engine/walker.py D:\\Hermes\\zhangyuzhixue_app_v2

前置:
    flutter run --dart-define=AUDIT_MODE=true 已在终端运行
    桌面不锁屏，窗口可见
"""
import sys
import time
import os
import ctypes

import pyautogui

# 确保目录在 path 中
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screenshot import init as init_ss, find_window, capture
from registry import REGISTRY, NavTarget

# ── DPI 检测 ──
def detect_dpi_scale() -> float:
    """检测系统 DPI 缩放因子 (96 DPI = 1.0)"""
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)  # PER_MONITOR_AWARE
        dpi = ctypes.windll.user32.GetDpiForSystem()
        return dpi / 96.0
    except Exception:
        return 1.0  # fallback

DPI_SCALE = detect_dpi_scale()

# ── 坐标映射（已缩放）──
from coordinate_map import get as coord_get, set_scale as coord_set_scale, get_tab
coord_set_scale(DPI_SCALE)

# 基准窗口尺寸
BASE_W = 390
BASE_H = 844
WINDOW_W = int(BASE_W * DPI_SCALE)
WINDOW_H = int(BASE_H * DPI_SCALE)


def click_tab(index: int):
    """点击底部 Tab（坐标来自 coordinate_map，已缩放）"""
    try:
        x, y = get_tab(index)
    except ValueError:
        print(f"  ⚠️ 无效的 Tab index: {index}")
        return
    print(f"  [Tab] 点击 Tab {index} → ({x}, {y}) (DPI={DPI_SCALE:.2f})")
    pyautogui.click(x, y)
    time.sleep(0.8)


def click_text(text: str):
    """根据 design→坐标映射点击文字（已缩放），未找到则 fallback"""
    coord = coord_get(text)
    if coord:
        x, y = coord
        print(f"  [点击] {text} → ({x}, {y}) (DPI={DPI_SCALE:.2f})")
        pyautogui.click(x, y)
    else:
        fallback_x = int(195 * DPI_SCALE)
        fallback_y = int(400 * DPI_SCALE)
        print(f"  [点击] {text} → ({fallback_x}, {fallback_y}) ⚠️ fallback: 未知文本坐标")
        pyautogui.click(fallback_x, fallback_y)
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
    print(f"DPI 缩放检测: {DPI_SCALE:.2f}x (窗口 {BASE_W}×{BASE_H} → {WINDOW_W}×{WINDOW_H})")

    # 1. 初始化截图目录
    ss_dir = init_ss(workspace)
    print(f"截图目录: {ss_dir}")

    # 2. 定位并调整窗口尺寸（已缩放）
    hwnd = find_window()
    import win32gui
    import win32con
    win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
    win32gui.SetForegroundWindow(hwnd)
    time.sleep(0.15)
    win32gui.MoveWindow(hwnd, 0, 0, WINDOW_W, WINDOW_H, True)
    time.sleep(0.5)

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
            continue

    print(f"\n✅ 走查完成。共 {len(all_screenshots)} 张截图。")
    print(f"NDJSON 日志已由 AuditLogger 写入 %TEMP%/zhangyuzhixue_audit.ndjson")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python walker.py <workspace_path>")
        sys.exit(1)
    main(sys.argv[1])
