#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Tuple


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "docs" / "功能说明与E2E.md"
DEFAULT_TEST_ROOTS = [
    ROOT / "Culler",
]


@dataclass(frozen=True)
class FeatureRow:
    feature_id: str
    name: str
    e2e_case: str
    automated: bool


TABLE_HEADER_RE = re.compile(r"^\|\s*功能ID\s*\|\s*功能名称\s*\|\s*当前行为（摘要）\s*\|\s*E2E 用例\s*\|\s*自动化\s*\|\s*$")
TABLE_ROW_RE = re.compile(r"^\|\s*(F-\d+)\s*\|\s*([^|]+?)\s*\|\s*([^|]*?)\s*\|\s*(E2E-\d+)\s*\|\s*(Yes|No)\s*\|\s*$")

# 为避免与示例图片名（例如 UITestSupport.swift 中的 "E2E-01.png"）冲突，
# 这里要求用例实现必须显式打印或包含形如 "E2E_CASE:E2E-01" 的标记。
E2E_CASE_MARK_RE = re.compile(r"\bE2E_CASE:(E2E-\d+)\b")


def die(msg: str, code: int = 2) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        die(f"Missing file: {path}")


def parse_feature_table(md: str) -> List[FeatureRow]:
    lines = md.splitlines()
    start_idx = None
    for i, line in enumerate(lines):
        if TABLE_HEADER_RE.match(line):
            start_idx = i
            break
    if start_idx is None:
        die("Could not find feature table header in docs/功能说明与E2E.md")

    rows: List[FeatureRow] = []
    for line in lines[start_idx + 2 :]:
        if not line.strip().startswith("|"):
            break
        m = TABLE_ROW_RE.match(line)
        if not m:
            continue
        feature_id, name, _summary, e2e_case, automated = m.groups()
        rows.append(
            FeatureRow(
                feature_id=feature_id.strip(),
                name=name.strip(),
                e2e_case=e2e_case.strip(),
                automated=(automated.strip().lower() == "yes"),
            )
        )

    if not rows:
        die("No feature rows parsed from docs/功能说明与E2E.md")
    return rows


def iter_test_files(roots: Iterable[Path]) -> Iterable[Path]:
    for root in roots:
        if not root.exists():
            continue
        for dirpath, _dirnames, filenames in os.walk(root):
            for fn in filenames:
                if fn.endswith(".swift") or fn.endswith(".m") or fn.endswith(".mm"):
                    yield Path(dirpath) / fn


def collect_e2e_cases_in_tests(roots: Iterable[Path]) -> Tuple[set[str], dict[str, List[str]]]:
    cases: set[str] = set()
    case_to_files: dict[str, List[str]] = {}

    for path in iter_test_files(roots):
        text = read_text(path)
        found = set(E2E_CASE_MARK_RE.findall(text))
        for c in found:
            cases.add(c)
            case_to_files.setdefault(c, []).append(str(path.relative_to(ROOT)))

    return cases, case_to_files


def compute_coverage(features: List[FeatureRow], implemented_cases: set[str]) -> Tuple[int, int, float, List[FeatureRow]]:
    total = len(features)
    covered = 0
    missing: List[FeatureRow] = []
    for f in features:
        if not f.automated:
            missing.append(f)
            continue
        if f.e2e_case in implemented_cases:
            covered += 1
        else:
            missing.append(f)

    ratio = (covered / total) if total else 0.0
    return covered, total, ratio, missing


def main(argv: List[str]) -> int:
    threshold = 0.90
    output_json = False
    roots = list(DEFAULT_TEST_ROOTS)

    for arg in argv[1:]:
        if arg.startswith("--threshold="):
            threshold = float(arg.split("=", 1)[1])
        elif arg == "--json":
            output_json = True
        elif arg.startswith("--root="):
            roots = [ROOT / arg.split("=", 1)[1]]
        else:
            die(f"Unknown arg: {arg}")

    doc = read_text(DOC_PATH)
    features = parse_feature_table(doc)
    implemented_cases, case_to_files = collect_e2e_cases_in_tests(roots)

    covered, total, ratio, missing = compute_coverage(features, implemented_cases)

    report = {
        "covered": covered,
        "total": total,
        "coverage": ratio,
        "threshold": threshold,
        "missing": [
            {"id": f.feature_id, "name": f.name, "e2e": f.e2e_case, "automated": f.automated}
            for f in missing
            if f.automated
        ],
        "found_cases": sorted(implemented_cases),
        "case_locations": {k: v for k, v in sorted(case_to_files.items(), key=lambda kv: kv[0])},
    }

    if output_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        pct = ratio * 100.0
        print(f"E2E feature coverage: {covered}/{total} = {pct:.1f}% (threshold {threshold*100:.0f}%)")
        if missing:
            automated_missing = [m for m in missing if m.automated]
            if automated_missing:
                print("\nMissing automated E2E cases:")
                for f in automated_missing:
                    print(f"- {f.feature_id} {f.name}: {f.e2e_case} not found in tests")

    return 0 if ratio >= threshold else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
