"""
OCR 定位器 — 基于 PaddleOCR 的按钮坐标识别。
输入截图路径，输出 {文字: (center_x, center_y)} 映射。
优先 GPU，fallback CPU。
"""
import os
import sys
import ctypes
import numpy as np

# DPI 感知（OCR 坐标是物理像素，需与 pyautogui 一致）
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)
except Exception:
    pass

_ocr = None
_cache = {}  # screenshot_path → {text: (x, y)}


def _init():
    """惰性初始化 PaddleOCR（单例）"""
    global _ocr
    if _ocr is not None:
        return
    from paddleocr import PaddleOCR
    _ocr = PaddleOCR(lang='ch')
    # 首次初始化会自动下载模型（~1.2GB），后续使用缓存


def locate(screenshot: str | np.ndarray) -> dict[str, tuple[int, int]]:
    """对截图运行 OCR，返回 {文字: (中心_x, 中心_y)} 映射。

    接受文件路径 (str) 或内存图像 (np.ndarray)。
    str 路径的结果缓存在内存中，同一路径不重复 OCR。
    """

    # str → 有缓存检查；ndarray → 跳过缓存
    if isinstance(screenshot, str) and screenshot in _cache:
        return _cache[screenshot]

    _init()
    result = _ocr.ocr(screenshot)

    if not result or not isinstance(result, list) or len(result) == 0:
        mapping = {}
    else:
        page = result[0]
        texts = page.get('rec_texts', [])
        scores = page.get('rec_scores', [])
        boxes = page.get('rec_boxes', [])

        mapping = {}
        for i in range(len(texts)):
            raw = texts[i]
            conf = scores[i] if i < len(scores) else 0
            if conf < 0.5:
                continue  # 过滤低置信度
            box = boxes[i] if i < len(boxes) else None
            if box is None or len(box) < 4:
                continue
            cx = int((box[0] + box[2]) / 2)
            cy = int((box[1] + box[3]) / 2)
            # 取完整文字作为 key，空格替换掉
            key = raw.replace(' ', '')
            mapping[key] = (cx, cy)
            # 同时注册子串映射（"自主选题·消耗20积分" → "自主选题"）
            for sub in _TARGET_SUBSTRINGS:
                if sub in key:
                    mapping[sub] = (cx, cy)

    if isinstance(screenshot, str):
        _cache[screenshot] = mapping
    return mapping


def find_text(text: str, source: str | dict) -> tuple[int, int] | None:
    """在截图中查找指定文字，返回中心坐标。

    source 可以是文件路径 (str) 或已处理好的映射表 (dict)。
    """
    mapping = locate(source) if isinstance(source, str) else source
    if text in mapping:
        return mapping[text]
    # fallback：模糊匹配
    for key, coord in mapping.items():
        if text in key or key in text:
            return coord
    return None


def clear_cache():
    """清空 OCR 缓存"""
    _cache.clear()


# 走查中需要点击的固定文本（用于子串匹配）
_TARGET_SUBSTRINGS = [
    '智能组卷', '自主选题', '我的组卷', '发现组卷', '收藏', '组卷历史',
    '返回', '注册', '退出登录', '退出',
    '第一张试卷', '其它答案', '答题卡',
    '选项A', '选项B', '选项C', '选项D', '提交答案',
    '下一题', '评分', '解题地图',
    '第一门课', '第一章', '第一个作业', '第一个偏好',
    '讲义', '作业', '开始做题', '确认组卷',
    '编辑', '统计', '成就', '等级', '积分', '做题历史',
    '学习偏好', '同步状态', '关于',
    '首页', '推荐', '组卷', '我的',
]


if __name__ == '__main__':
    # 快速测试
    import time
    test_img = sys.argv[1] if len(sys.argv) > 1 else None
    if test_img and os.path.exists(test_img):
        t0 = time.time()
        m = locate(test_img)
        print(f"OCR 耗时: {time.time()-t0:.2f}s")
        print(f"识别 {len(m)} 个文字块")
        for k, v in sorted(m.items(), key=lambda x: x[1][1]):
            print(f"  {k:20s} → ({v[0]:>4d}, {v[1]:>4d})")
