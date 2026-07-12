"""
CLI 交互式导航 — 截图→OCR→决策→点击。

用法:
    python nav_engine/walker.py init <workspace>       # 初始化，返回 hwnd
    python nav_engine/walker.py snap <hwnd> [label]    # 截图+OCR，列出可见文字
    python nav_engine/walker.py click <hwnd> <文字>     # 点击文字
    python nav_engine/walker.py tab <hwnd> <index>     # 点底部Tab (0=首页 1=推荐 2=组卷 3=我的)
    python nav_engine/walker.py back <hwnd>            # 点返回按钮

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

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screenshot import init as init_ss, find_window, capture
from ocr_locator import find_text, locate


# ── DPI ──
def detect_dpi_scale() -> float:
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
        dpi = ctypes.windll.user32.GetDpiForSystem()
        return dpi / 96.0
    except Exception:
        return 1.0

DPI_SCALE = detect_dpi_scale()

BACK_BTN_CLIENT_X = 24   # 返回图标在客户区内的 X
BACK_BTN_CLIENT_Y = 28   # 返回图标在客户区内的 Y（AppBar 56px，居中≈28）
WINDOW_W = int(390 * DPI_SCALE)
WINDOW_H = int(844 * DPI_SCALE)

_last_full_path: str | None = None


# ── 底层工具函数 ──

def _client_origin(hwnd: int) -> tuple[int, int]:
    return win32gui.ClientToScreen(hwnd, (0, 0))


def _check_bounds(x: int, y: int, label: str) -> bool:
    if x < 0 or x >= WINDOW_W or y < 0 or y >= WINDOW_H:
        print(f"  ⚠️ {label} ({x}, {y}) 超出窗口 {WINDOW_W}×{WINDOW_H}，跳过")
        return False
    return True


def _ocr_screen() -> dict[str, tuple[int, int]]:
    global _last_full_path
    if _last_full_path is None:
        raise RuntimeError("无可用截图，请先执行 snap 命令")
    return locate(_last_full_path)


def _get_tab_coords(hwnd: int, index: int) -> tuple[int, int]:
    ox, oy = win32gui.ClientToScreen(hwnd, (0, 0))
    client_rect = win32gui.GetClientRect(hwnd)
    cw = client_rect[2] - client_rect[0]
    ch = client_rect[3] - client_rect[1]
    tab_cy = oy + ch - 64 // 2
    tab_cx = ox + cw * (2 * index + 1) // 8
    return (tab_cx, tab_cy)


# ── 动作指令 ──

def click_tab(index: int, hwnd: int):
    label = {0: '首页', 1: '推荐', 2: '组卷', 3: '我的'}.get(index)
    if label is None:
        print(f"  ⚠️ 无效的 Tab index: {index}")
        return
    x, y = _get_tab_coords(hwnd, index)
    if not _check_bounds(x, y, f"Tab:{label}"):
        return
    print(f"  [Tab] {label} → ({x}, {y}) 📷")
    pyautogui.click(x, y)
    time.sleep(0.8)


def click_text(text: str, hwnd: int):
    if text == "返回":
        ox, oy = _client_origin(hwnd)
        bx, by = ox + BACK_BTN_CLIENT_X, oy + BACK_BTN_CLIENT_Y
        if not _check_bounds(bx, by, "返回"):
            return
        print(f"  [返回] → ({bx}, {by}) 📷")
        pyautogui.click(bx, by)
        time.sleep(0.5)
        return

    mapping = _ocr_screen()
    coord = find_text(text, mapping)
    if coord:
        x, y = coord
        ox, oy = _client_origin(hwnd)
        screen_x, screen_y = ox + x, oy + y
        if _check_bounds(screen_x, screen_y, f"OCR:{text}"):
            print(f"  [点击] {text} → ({screen_x}, {screen_y}) 📷")
            pyautogui.click(screen_x, screen_y)
            time.sleep(0.5)
            return

    avail = [f"{k}({v[0]},{v[1]})" for k, v in sorted(mapping.items(), key=lambda x: x[1][1])]
    print(f"  ❌ 未找到 \"{text}\" (src={_last_full_path and os.path.basename(_last_full_path)}) — OCR 读到 {len(avail)} 个: {' / '.join(avail[:12])}{' ...' if len(avail)>12 else ''}")


# ── CLI 入口命令 ──

def cmd_init(workspace: str) -> int:
    global _last_full_path
    ss_dir = init_ss(workspace)
    print(f"截图目录: {ss_dir}")
    hwnd = find_window()
    win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
    win32gui.SetForegroundWindow(hwnd)
    time.sleep(0.15)
    win32gui.MoveWindow(hwnd, 0, 0, WINDOW_W, WINDOW_H, True)
    time.sleep(0.5)
    _last_full_path = capture(hwnd, "init", "snap")
    print(f"窗口句柄: {hwnd}")
    return hwnd


def cmd_snap(hwnd: int, label: str = "snap"):
    import mss, tempfile
    ss_dir = os.path.join(os.path.dirname(__file__), "..", "screenshots", "cli")
    os.makedirs(ss_dir, exist_ok=True)
    # 清理旧临时截图，最多保留 10 张
    old = sorted(os.listdir(ss_dir))
    for f in old[:-9]:  # 保留最新的 9 张 + 当前这张 = 10
        os.remove(os.path.join(ss_dir, f))
    tmp_path = os.path.join(ss_dir, f"{label}_{int(time.time()*1000)}.png")
    client_rect = win32gui.GetClientRect(hwnd)
    with mss.mss() as sct:
        monitor = {
            "left": win32gui.ClientToScreen(hwnd, (0, 0))[0],
            "top": win32gui.ClientToScreen(hwnd, (0, 0))[1],
            "width": client_rect[2] - client_rect[0],
            "height": client_rect[3] - client_rect[1],
        }
        img = sct.grab(monitor)
        mss.tools.to_png(img.rgb, img.size, output=tmp_path)
    mapping = locate(tmp_path)
    print(f"\n[{label}] OCR 识别到 {len(mapping)} 个文字：")
    for k, v in sorted(mapping.items(), key=lambda x: x[1][1]):
        print(f"  ({v[0]:>4d}, {v[1]:>4d})  {k}")
    print()


if __name__ == "__main__":
    argc = len(sys.argv)
    if argc < 2:
        print(__doc__); sys.exit(1)

    cmd = sys.argv[1]
    workspace = sys.argv[2] if argc > 2 else None

    if cmd == "init" and workspace:
        hwnd = cmd_init(workspace)
        print(f"HWND={hwnd}")
    elif cmd == "snap" and argc >= 3:
        cmd_snap(int(sys.argv[2]), sys.argv[3] if argc > 3 else "snap")
    elif cmd == "click" and argc >= 4:
        hwnd, text = int(sys.argv[2]), sys.argv[3]
        import mss, tempfile
        ss_dir = os.path.join(os.path.dirname(__file__), "..", "screenshots", "cli")
        os.makedirs(ss_dir, exist_ok=True)
        old = sorted(os.listdir(ss_dir))
        for f in old[:-9]:
            os.remove(os.path.join(ss_dir, f))
        tmp_path = os.path.join(ss_dir, f"click_{int(time.time()*1000)}.png")
        client_rect = win32gui.GetClientRect(hwnd)
        with mss.mss() as sct:
            monitor = {
                "left": win32gui.ClientToScreen(hwnd, (0, 0))[0],
                "top": win32gui.ClientToScreen(hwnd, (0, 0))[1],
                "width": client_rect[2] - client_rect[0],
                "height": client_rect[3] - client_rect[1],
            }
            img = sct.grab(monitor)
            mss.tools.to_png(img.rgb, img.size, output=tmp_path)
        _last_full_path = tmp_path
        click_text(text, hwnd)
    elif cmd == "tab" and argc >= 4:
        hwnd, idx = int(sys.argv[2]), int(sys.argv[3])
        click_tab(idx, hwnd)
        _last_full_path = capture(hwnd, "cli", "nav")
    elif cmd == "back" and argc >= 3:
        click_text("返回", int(sys.argv[2]))
    else:
        print(__doc__); sys.exit(1)
