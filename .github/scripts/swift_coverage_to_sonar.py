#!/usr/bin/env python3

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


def normalize_path(raw_path: str, repo_root: Path) -> str:
    path = Path(raw_path)

    if not path.is_absolute():
        return path.as_posix()

    try:
        return path.resolve().relative_to(repo_root).as_posix()
    except ValueError:
        return path.as_posix()


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "usage: swift_coverage_to_sonar.py <coverage.json> <coverage.xml>",
            file=sys.stderr,
        )
        return 1

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    repo_root = Path.cwd().resolve()

    line_hits_by_file: dict[str, dict[int, int]] = defaultdict(dict)

    current_path: str | None = None
    for raw_line in input_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue

        if line.startswith("SF:"):
            current_path = normalize_path(line[3:], repo_root)
            continue

        if line.startswith("DA:") and current_path is not None:
            line_data = line[3:]
            parts = line_data.split(",")
            if len(parts) < 2:
                continue

            line_number = int(parts[0])
            execution_count = int(parts[1])
            file_line_hits = line_hits_by_file[current_path]
            current_count = file_line_hits.get(line_number, 0)
            if execution_count > current_count:
                file_line_hits[line_number] = execution_count
            else:
                file_line_hits.setdefault(line_number, current_count)
            continue

        if line == "end_of_record":
            current_path = None

    root = ET.Element("coverage", version="1")

    for file_path in sorted(line_hits_by_file):
        file_element = ET.SubElement(root, "file", path=file_path)

        for line_number in sorted(line_hits_by_file[file_path]):
            ET.SubElement(
                file_element,
                "lineToCover",
                lineNumber=str(line_number),
                covered=str(line_hits_by_file[file_path][line_number] > 0).lower(),
            )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(output_path, encoding="utf-8", xml_declaration=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())