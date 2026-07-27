#!/usr/bin/env python3
"""Read-only production smoke tests shared by deployment workflows."""

from __future__ import annotations

import argparse
import ssl
import sys
from dataclasses import dataclass
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


@dataclass(frozen=True)
class Check:
    url: str
    status: int
    contains: bytes | None = None


CHECKS = (
    Check("https://zhangyuzhixue.top/", 200, "专注高考数学".encode()),
    Check("https://zhangyuzhixue.top/software.html", 200),
    Check("https://zhangyuzhixue.top/courses.html", 200),
    Check("https://zhangyuzhixue.top/teacher/", 200),
    Check("https://zhangyuzhixue.top/teacher/login.html", 200, "教师登录".encode()),
    Check("https://zhangyuzhixue.top/teacher/teacher-common.js", 200, b"API_BASE"),
    Check("https://zhangyuzhixue.top/teacher/teacher-styles.css", 200),
    Check("https://zhangyuzhixue.top/robots.txt", 200, b"Sitemap:"),
    Check("https://zhangyuzhixue.top/sitemap.xml", 200, b"<urlset"),
    Check("https://zhangyuzhixue.top/assets/images/share-cover.jpg", 200),
    Check("https://zhangyuzhixue.top/__production_smoke_missing__", 404, "没有找到这个页面".encode()),
    Check("https://zhangyuzhixue.zhtec123.com/privacy.html", 200),
    Check("https://zhangyuzhixue.zhtec123.com/api/v1/auth/login/", 405),
)


def request(check: Check, timeout: float) -> tuple[int, bytes]:
    request = Request(check.url, headers={"User-Agent": "zhangyuzhixue-release-smoke/1.0"})
    try:
        with urlopen(request, timeout=timeout, context=ssl.create_default_context()) as response:
            return response.status, response.read()
    except HTTPError as error:
        return error.code, error.read()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=float, default=15.0)
    args = parser.parse_args()
    failures = 0

    for check in CHECKS:
        try:
            status, body = request(check, args.timeout)
            valid = status == check.status and (check.contains is None or check.contains in body)
            marker = "PASS" if valid else "FAIL"
            print(f"{marker} {status} {check.url}")
            if not valid:
                failures += 1
        except (URLError, TimeoutError, OSError) as error:
            print(f"FAIL ERR {check.url}: {error}")
            failures += 1

    print(f"Production smoke failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
