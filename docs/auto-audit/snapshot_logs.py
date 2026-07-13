#!/usr/bin/env python3
"""
snapshot_logs.py — 自动归档最新的审计 NDJSON 和 winnav 日志。

用法：
    python docs/auto-audit/snapshot_logs.py

功能：
    - 找到 %TEMP%\\zhangyuzhixue_audit.ndjson 和 %TEMP%\\winnav\\logs\\ 中最新的日志
    - 复制到 docs/auto-audit/log-snapshots/，文件名加上当前时间戳
    - 保留最近 10 份，更早的自动删除
"""

import os
import sys
import shutil
import glob
from datetime import datetime

# ── 配置（可通过环境变量覆盖测试） ──

DOCS_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
)
SNAPSHOT_DIR = os.environ.get("SNAPSHOT_DIR") or os.path.join(DOCS_DIR, "log-snapshots")
MAX_KEEP = int(os.environ.get("SNAPSHOT_MAX_KEEP", "10"))

NDJSON_SRC = os.environ.get("SNAPSHOT_NDJSON_SRC") or os.path.join(
    os.environ.get("TEMP", os.path.expanduser("~")),
    "zhangyuzhixue_audit.ndjson",
)
WINNAV_LOG_DIR = os.environ.get("SNAPSHOT_WINNAV_DIR") or os.path.join(
    os.environ.get("TEMP", os.path.expanduser("~")),
    "winnav", "logs",
)


def log(msg: str):
    print(f"[SNAPSHOT] {msg}")


def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


def latest_winnav_log() -> str | None:
    """返回 WINNAV_LOG_DIR 中最新 winnav_*.json 的绝对路径，无则 None。"""
    pattern = os.path.join(WINNAV_LOG_DIR, "winnav_*.json")
    files = sorted(glob.glob(pattern), key=os.path.getmtime, reverse=True)
    return files[0] if files else None


def snapshot_file(src: str, prefix: str, ext: str) -> str | None:
    """复制 src 到快照目录，返回目标路径，源不存在则返回 None。"""
    if not os.path.isfile(src):
        log(f"⚠ 源文件不存在，跳过: {src}")
        return None
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    dst = os.path.join(SNAPSHOT_DIR, f"{prefix}_{ts}.{ext}")
    shutil.copy2(src, dst)
    log(f"✅ {src} → {dst}")
    return dst


def _parse_ts_from_name(fname: str) -> str:
    """从文件名中提取时间戳段用于排序。
    格式: prefix_YYYYMMDD_HHMMSS.ext → 返回 YYYYMMDD_HHMMSS。
    解析失败返回空字符串（排到最前，优先删除）。
    """
    # fname 如 audit_20260713_162344.ndjson → 提取 "20260713_162344"
    parts = os.path.splitext(fname)[0].split("_", 1)
    if len(parts) == 2:
        return parts[1]
    return ""


def cleanup_old(prefix: str):
    """对快照目录中指定前缀的文件，保留最近的 MAX_KEEP 份。"""
    files = [f for f in os.listdir(SNAPSHOT_DIR)
             if f.startswith(prefix) and os.path.isfile(os.path.join(SNAPSHOT_DIR, f))]
    # 按文件名中的时间戳降序排列（最新靠前）
    files.sort(key=lambda f: _parse_ts_from_name(f), reverse=True)

    if len(files) <= MAX_KEEP:
        return

    for old in files[MAX_KEEP:]:
        old_path = os.path.join(SNAPSHOT_DIR, old)
        try:
            os.remove(old_path)
            log(f"🗑 删除旧快照: {old}")
        except OSError as e:
            log(f"⚠ 删除失败 {old}: {e}")


def main():
    ensure_dir(SNAPSHOT_DIR)
    log(f"快照目录: {SNAPSHOT_DIR}")

    # 1. 快照 NDJSON
    snapshot_file(NDJSON_SRC, "audit", "ndjson")

    # 2. 快照最新的 winnav 日志
    winnav_src = latest_winnav_log()
    if winnav_src:
        snapshot_file(winnav_src, "winnav", "json")
    else:
        log("⚠ 未找到 winnav 日志文件")

    # 3. 清理旧文件
    cleanup_old("audit_")
    cleanup_old("winnav_")

    log("完成。")


if __name__ == "__main__":
    main()
