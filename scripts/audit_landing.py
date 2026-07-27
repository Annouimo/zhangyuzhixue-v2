#!/usr/bin/env python3
"""Validate the static Landing release before production packaging."""

from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit


PUBLIC_PAGES = {
    "index.html",
    "software.html",
    "courses.html",
    "course-derivative.html",
    "course-geometry.html",
    "course-innovation.html",
    "team.html",
    "about.html",
    "privacy.html",
    "terms.html",
}


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.elements: list[tuple[str, dict[str, str]]] = []
        self.h1_count = 0
        self.json_ld: list[str] = []
        self._json_buffer: list[str] | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {key: value or "" for key, value in attrs}
        self.elements.append((tag, values))
        if tag == "h1":
            self.h1_count += 1
        if tag == "script" and values.get("type") == "application/ld+json":
            self._json_buffer = []

    def handle_data(self, data: str) -> None:
        if self._json_buffer is not None:
            self._json_buffer.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "script" and self._json_buffer is not None:
            self.json_ld.append("".join(self._json_buffer))
            self._json_buffer = None


def is_local_reference(value: str) -> bool:
    parts = urlsplit(value)
    return not parts.scheme and not parts.netloc and not value.startswith(("#", "data:"))


def validate(root: Path) -> list[str]:
    issues: list[str] = []
    html_files = sorted(root.glob("*.html"))
    existing_pages = {path.name for path in html_files}
    missing_pages = PUBLIC_PAGES - existing_pages
    issues.extend(f"missing public page: {name}" for name in sorted(missing_pages))

    for path in html_files:
        parser = PageParser()
        parser.feed(path.read_text(encoding="utf-8"))

        if path.name != "internal.html" and parser.h1_count != 1:
            issues.append(f"{path.name}: expected one h1, found {parser.h1_count}")

        if path.name in PUBLIC_PAGES:
            canonical = [
                attrs.get("href")
                for tag, attrs in parser.elements
                if tag == "link" and attrs.get("rel") == "canonical"
            ]
            if len(canonical) != 1:
                issues.append(f"{path.name}: expected one canonical link")
            properties = {
                attrs.get("property")
                for tag, attrs in parser.elements
                if tag == "meta" and attrs.get("property")
            }
            for property_name in ("og:title", "og:description", "og:url", "og:image"):
                if property_name not in properties:
                    issues.append(f"{path.name}: missing {property_name}")

        for tag, attrs in parser.elements:
            if tag == "img" and "alt" not in attrs:
                issues.append(f"{path.name}: image missing alt: {attrs.get('src', '')}")
            for attr_name in ("href", "src"):
                value = attrs.get(attr_name)
                if not value or not is_local_reference(value):
                    continue
                relative = urlsplit(value).path
                if not relative:
                    continue
                target = (path.parent / relative).resolve()
                if not target.exists():
                    issues.append(f"{path.name}: missing {attr_name} target: {value}")

        for value in parser.json_ld:
            try:
                json.loads(value)
            except json.JSONDecodeError as error:
                issues.append(f"{path.name}: invalid JSON-LD: {error}")

    for required in ("robots.txt", "sitemap.xml", "404.html", "assets/images/share-cover.jpg"):
        if not (root / required).is_file():
            issues.append(f"missing release file: {required}")

    sitemap = root / "sitemap.xml"
    if sitemap.is_file():
        try:
            ET.parse(sitemap)
        except ET.ParseError as error:
            issues.append(f"invalid sitemap.xml: {error}")

    robots = root / "robots.txt"
    if robots.is_file():
        content = robots.read_text(encoding="utf-8")
        if "Sitemap: https://zhangyuzhixue.top/sitemap.xml" not in content:
            issues.append("robots.txt: production sitemap declaration is missing")
        for private_path in ("/internal.html", "/teacher/"):
            if f"Disallow: {private_path}" not in content:
                issues.append(f"robots.txt: missing Disallow for {private_path}")

    return issues


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="landing", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"Landing directory does not exist: {root}", file=sys.stderr)
        return 2

    issues = validate(root)
    print(f"Landing root: {root}")
    print(f"Issues: {len(issues)}")
    for issue in issues:
        print(f"- {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    raise SystemExit(main())
