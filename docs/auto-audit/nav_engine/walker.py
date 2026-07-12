"""
自动走查主流程 — pyautogui 遍历 34 页，截图 + 触发 NDJSON。

用法:
    python nav_engine/walker.py D:\\Hermes\\zhangyuzhixue_app_v2

前置:
    flutter run --dart-define=AUDIT_MODE=true 已在终端运行
    桌面不锁屏，窗口可见
"""
import os
import sys
import time
import ctypes

import pyautogui
import win32gui
import win32con

# 确保目录在 path 中
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screenshot import init as init_ss, find_window, capture
from registry import REGISTRY, NavTarget

# ── DPI 检测 ──
def detect_dpi_scale() -> float:
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
        dpi = ctypes.windll.user32.GetDpiForSystem()
        return dpi / 96.0
    except Exception:
        return 1.0

DPI_SCALE = detect_dpi_scale()

# ── OCR 定位器 ──
from ocr_locator import find_text, locate

# 窗口在屏幕左上角 (0,0)，客户区偏移量（与 screenshot.capture 保持一致）
CLIENT_OFFSET_X = int(8 * DPI_SCALE)
CLIENT_OFFSET_Y = int(30 * DPI_SCALE)

# 基准窗口尺寸（仅用于越界检查）
WINDOW_W = int(390 * DPI_SCALE)
WINDOW_H = int(844 * DPI_SCALE)

# 返回按钮（左箭头图标，无文字）— 在 Flutter AppBar 左上角
# 客户区内 AppBar 56px，返回图标中心 ≈ (24, 28) 客户区坐标
BACK_BTN_SCREEN_X = CLIENT_OFFSET_X + int(24 * DPI_SCALE)
BACK_BTN_SCREEN_Y = CLIENT_OFFSET_Y + int(28 * DPI_SCALE)


def _check_bounds(x: int, y: int, label: str) -> bool:
    """检查坐标是否在屏幕范围内，越界则跳过并返回 False"""
    if x < 0 or x >= WINDOW_W or y < 0 or y >= WINDOW_H:
        print(f"  ⚠️ {label} ({x}, {y}) 超出窗口 {WINDOW_W}×{WINDOW_H}，跳过")
        return False
    return True


def _ocr_screen(hwnd: int, page: str) -> dict[str, tuple[int, int]]:
    """截图当前窗口并 OCR，返回文字→坐标映射（截图作为审计轨迹保存）"""
    fpath = capture(hwnd, page, "ocr")
    return locate(fpath)


# 底部 Tab 标签文字
_TAB_LABELS = {0: '首页', 1: '推荐', 2: '组卷', 3: '我的'}


def click_tab(index: int, hwnd: int, page: str = "nav"):
    """点击底部 Tab — 实时截图 + OCR 定位"""
    label = _TAB_LABELS.get(index)
    if label is None:
        print(f"  ⚠️ 无效的 Tab index: {index}")
        return

    mapping = _ocr_screen(hwnd, page)
    coord = find_text(label, mapping)
    if not coord:
        print(f"  ⚠️ Tab \"{label}\" 未在页面中识别到")
        return

    x, y = coord
    screen_x = CLIENT_OFFSET_X + x
    screen_y = CLIENT_OFFSET_Y + y
    if not _check_bounds(screen_x, screen_y, f"Tab:{label}"):
        return
    print(f"  [Tab] {label} → ({screen_x}, {screen_y}) 📷")
    pyautogui.click(screen_x, screen_y)
    time.sleep(0.8)


def click_text(text: str, hwnd: int, page: str = "nav"):
    """点击页面上的文字 — 实时截图 + OCR 定位，找不到即报告为 UI 设计问题。

    特殊处理：
    - "返回"：Flutter 左箭头图标（无文字），硬编码坐标
    """
    if text == "返回":
        if not _check_bounds(BACK_BTN_SCREEN_X, BACK_BTN_SCREEN_Y, "返回"):
            return
        print(f"  [返回] → ({BACK_BTN_SCREEN_X}, {BACK_BTN_SCREEN_Y}) 📷")
        pyautogui.click(BACK_BTN_SCREEN_X, BACK_BTN_SCREEN_Y)
        time.sleep(0.5)
        return

    mapping = _ocr_screen(hwnd, page)
    coord = find_text(text, mapping)
    if coord:
        x, y = coord
        screen_x = CLIENT_OFFSET_X + x
        screen_y = CLIENT_OFFSET_Y + y
        if _check_bounds(screen_x, screen_y, f"OCR:{text}"):
            print(f"  [点击] {text} → ({screen_x}, {screen_y}) 📷")
            pyautogui.click(screen_x, screen_y)
            time.sleep(0.5)
            return

    # 没找到 → 这是 UI 设计的问题（缺少该按钮文本）
    print(f"  ❌ 未找到 \"{text}\" — OCR 未识别到此文字。请检查 UI 设计是否缺少该按钮文本")


def walk_target(tgt: NavTarget, hwnd: int):
    """执行单个页面的导航和截图"""
    results = []
    for action, *args in tgt.nav_seq:
        if action == "click_bottom_tab":
            click_tab(args[0], hwnd, tgt.name)
        elif action == "click_text":
            click_text(args[0], hwnd, tgt.name)
        elif action == "wait":
            time.sleep(args[0])
        elif action == "screenshot":
            fpath = capture(hwnd, tgt.name, args[0])
            results.append(fpath)
            print(f"  [截图] {tgt.name}/{args[0]} → {fpath}")
    return results


def main(workspace: str):
    """主走查流程"""
    print(f"DPI 缩放检测: {DPI_SCALE:.2f}x (窗口 {int(390*DPI_SCALE)}×{int(844*DPI_SCALE)})")

    # 1. 初始化截图目录
    ss_dir = init_ss(workspace)
    print(f"截图目录: {ss_dir}")

    # 2. 定位并调整窗口尺寸（已缩放）
    hwnd = find_window()
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
