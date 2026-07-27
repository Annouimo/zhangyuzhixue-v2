#!/usr/bin/env python3
"""Validate the independently released static Teacher Web bundle."""

from __future__ import annotations

import argparse
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit


RELEASE_FILES = (
    "about.html",
    "classes.html",
    "detail.html",
    "index.html",
    "login.html",
    "publish.html",
    "student.html",
    "students.html",
    "teacher-common.js",
    "teacher-styles.css",
)
EXPECTED_API_BASE = "https://zhangyuzhixue.zhtec123.com/api/v1"


class ReferenceParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.references: list[tuple[str, str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        for attribute in ("href", "src"):
            value = values.get(attribute)
            if value:
                self.references.append((attribute, value))


def local_target(page: Path, reference: str) -> Path | None:
    parts = urlsplit(reference)
    if parts.scheme or parts.netloc or reference.startswith(("#", "javascript:", "data:")):
        return None
    if parts.path.startswith("/"):
        return None
    return (page.parent / parts.path).resolve()


def validate(root: Path) -> list[str]:
    issues: list[str] = []
    expected = set(RELEASE_FILES)
    actual = {path.name for path in root.iterdir() if path.is_file()}
    for name in sorted(expected - actual):
        issues.append(f"missing release file: {name}")
    for name in sorted(actual - expected):
        issues.append(f"unmanaged file in Teacher Web root: {name}")

    for page in sorted(root.glob("*.html")):
        parser = ReferenceParser()
        try:
            content = page.read_text(encoding="utf-8")
        except UnicodeDecodeError as error:
            issues.append(f"{page.name}: invalid UTF-8: {error}")
            continue
        parser.feed(content)
        if "<title>" not in content or "章鱼智学" not in content:
            issues.append(f"{page.name}: missing branded title")
        for attribute, reference in parser.references:
            target = local_target(page, reference)
            if target is not None and not target.is_file():
                issues.append(f"{page.name}: missing {attribute} target: {reference}")

    common_js = root / "teacher-common.js"
    if common_js.is_file():
        content = common_js.read_text(encoding="utf-8")
        matches = re.findall(r"const\s+API_BASE\s*=\s*['\"]([^'\"]+)", content)
        if matches != [EXPECTED_API_BASE]:
            issues.append(f"teacher-common.js: expected API_BASE {EXPECTED_API_BASE}")
        for required in ("function requireAuth", "function clearAuth", "function tryRefresh"):
            if required not in content:
                issues.append(f"teacher-common.js: missing auth function: {required}")

    shared_logo = root.parent / "images" / "logo-mark-96.png"
    if not shared_logo.is_file():
        issues.append("missing shared dependency: landing/images/logo-mark-96.png")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="landing/teacher", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"Teacher Web directory does not exist: {root}", file=sys.stderr)
        return 2
    issues = validate(root)
    print(f"Teacher Web root: {root}")
    print(f"Release files: {len(RELEASE_FILES)}")
    print(f"Issues: {len(issues)}")
    for issue in issues:
        print(f"- {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    raise SystemExit(main())
