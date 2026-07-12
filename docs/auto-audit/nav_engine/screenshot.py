"""
截图模块 — 定向裁剪 Flutter 窗口，不截全屏。
"""
import os
import time
from datetime import datetime
import mss
import win32gui
import win32con


WINDOW_TITLE_PREFIX = "flutter_app"  # 窗口标题前缀
WINDOW_SIZE = (390, 844)             # 目标窗口尺寸
SCREENSHOT_DIR = None                # 在 init 时设置


def init(workspace: str):
    """初始化截图目录（在 docs/auto-audit/screenshots/ 下建日期子目录）"""
    global SCREENSHOT_DIR
    base = os.path.join(workspace, "docs", "auto-audit", "screenshots")
    date_str = datetime.now().strftime("%Y-%m-%d")
    SCREENSHOT_DIR = os.path.join(base, date_str)
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    return SCREENSHOT_DIR


def find_window() -> int:
    """查找 Flutter 窗口句柄。返回 HWND 或抛出异常。"""
    def enum_callback(hwnd, targets):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if "flutter_app" in title.lower() or "章鱼" in title:
                targets.append(hwnd)
    targets = []
    win32gui.EnumWindows(enum_callback, targets)
    if not targets:
        raise RuntimeError("未找到 Flutter app 窗口")
    return targets[0]


def ensure_foreground(hwnd: int):
    """确保窗口置前并调整到标准尺寸位置。"""
    win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
    win32gui.SetForegroundWindow(hwnd)
    time.sleep(0.15)
    w, h = WINDOW_SIZE
    win32gui.MoveWindow(hwnd, 0, 0, w, h, True)
    time.sleep(0.5)


def capture(hwnd: int, page: str, dimension: str = "full") -> str:
    """定向截取 Flutter 窗口内容，保存为 PNG。

    Args:
        hwnd: 窗口句柄
        page: 页面英文名（如 index, exam-pick）
        dimension: 维度标识（如 V1, V2, full）

    Returns:
        截图文件的绝对路径
    """
    rect = win32gui.GetWindowRect(hwnd)
    client_rect = win32gui.GetClientRect(hwnd)

    with mss.mss() as sct:
        monitor = {
            "left": rect[0] + 8,       # 去掉窗口边框
            "top": rect[1] + 30,        # 去掉标题栏
            "width": client_rect[2] - client_rect[0],
            "height": client_rect[3] - client_rect[1],
        }
        img = sct.grab(monitor)

    fname = f"{page}_{dimension}.png"
    fpath = os.path.join(SCREENSHOT_DIR, fname)
    mss.tools.to_png(img.rgb, img.size, output=fpath)
    return fpath
