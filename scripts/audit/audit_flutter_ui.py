"""Report Flutter UI patterns that should be migrated to project primitives.

The default mode is informational while legacy code is being reduced. Pass
``--strict`` to return a non-zero exit code when findings remain.
"""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOTS = (ROOT / "flutter_app" / "lib", ROOT / "packages" / "shared" / "lib")

RULES = {
    "hard-coded font size": re.compile(r"\bfontSize\s*:"),
    "numeric EdgeInsets": re.compile(
        r"EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^\n)]*\b\d+(?:\.\d+)?"
    ),
    "raw Material button": re.compile(
        r"\b(?:ElevatedButton|FilledButton|OutlinedButton|TextButton)(?:\.icon)?\s*\("
    ),
    "raw AlertDialog": re.compile(r"\bAlertDialog\s*\("),
    "legacy BottomNavigationBar": re.compile(r"\bBottomNavigationBar\s*\("),
    "shrunk tap target": re.compile(r"MaterialTapTargetSize\.shrinkWrap"),
}

ALLOWLIST_PARTS = {
    "theme/app_theme.dart",
    "theme/app_typography.dart",
    "theme/app_tokens.dart",
    "widgets/app_button.dart",
    "widgets/app_dialog.dart",
}


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    findings: list[tuple[str, str, int]] = []
    for source_root in SOURCE_ROOTS:
        for path in source_root.rglob("*.dart"):
            rel = relative(path)
            if any(rel.endswith(part) for part in ALLOWLIST_PARTS):
                continue
            for line_number, line in enumerate(
                path.read_text(encoding="utf-8").splitlines(), start=1
            ):
                for label, pattern in RULES.items():
                    if pattern.search(line):
                        findings.append((label, rel, line_number))

    counts = Counter(label for label, _, _ in findings)
    print("Flutter UI audit (legacy-aware report)")
    for label in RULES:
        print(f"- {label}: {counts[label]}")
    if findings:
        print("\nFindings:")
        for label, path, line in findings:
            print(f"{path}:{line}: {label}")

    return 1 if args.strict and findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
