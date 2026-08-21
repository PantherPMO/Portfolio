"""
psql_parse.py — deterministic parser for psql aligned-format output files.

Project 01 · COMMUNICATE stage.

PURPOSE
-------
Every figure that appears on a chart in this project is read from a committed
output file in analysis/query_results/ by this parser. No analytical value is
typed by hand anywhere in the chart pipeline.

INPUT FORMAT
------------
psql's default "aligned" output, as produced by `psql -f script.sql -o file.txt`:

     col_a | col_b
    -------+-------
     v1    | v2
    (1 row)

A single file may contain several such blocks, one per statement.

GUARANTEES
----------
* Values are returned as strings exactly as psql wrote them. Numeric coercion
  happens only where a caller explicitly asks for it, and never changes
  precision or rounding.
* An empty field becomes None, not 0 and not "".
* The declared "(N rows)" footer is asserted against the number of parsed rows.
  A mismatch raises. This is the tripwire that would catch a truncated or
  partially written output file.

No dependency beyond the standard library.
"""

from __future__ import annotations

import re
from pathlib import Path

_RULE = re.compile(r"^-+(\+-+)*$")
_ROWCOUNT = re.compile(r"^\((\d+) rows?\)$")


class Block:
    """One result set from a psql output file."""

    def __init__(self, columns: list[str], rows: list[dict[str, str | None]], index: int):
        self.columns = columns
        self.rows = rows
        self.index = index  # 1-based position within the file

    def __len__(self) -> int:
        return len(self.rows)

    def where(self, **equals) -> "Block":
        """Filter rows by exact column equality. Returns a new Block."""
        for key in equals:
            if key not in self.columns:
                raise KeyError(f"block {self.index}: no column {key!r}; has {self.columns}")
        kept = [r for r in self.rows if all(r.get(k) == v for k, v in equals.items())]
        return Block(self.columns, kept, self.index)

    def col(self, name: str) -> list[str | None]:
        if name not in self.columns:
            raise KeyError(f"block {self.index}: no column {name!r}; has {self.columns}")
        return [r[name] for r in self.rows]

    def nums(self, name: str) -> list[float]:
        """Column as floats. Empty cells raise — use .col() if None is expected."""
        out = []
        for v in self.col(name):
            if v is None:
                raise ValueError(f"block {self.index}: empty cell in numeric column {name!r}")
            out.append(float(v))
        return out

    def one(self, name: str) -> str:
        """Single scalar from a single-row block."""
        if len(self.rows) != 1:
            raise ValueError(f"block {self.index}: expected exactly 1 row, found {len(self.rows)}")
        v = self.rows[0][name]
        if v is None:
            raise ValueError(f"block {self.index}: column {name!r} is empty")
        return v

    def num(self, name: str) -> float:
        return float(self.one(name))


def parse_file(path: str | Path) -> list[Block]:
    """Parse every result block in a psql aligned-output file, in order."""
    path = Path(path)
    lines = path.read_text(encoding="utf-8").splitlines()

    blocks: list[Block] = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        # A rule line means the PREVIOUS line was the header.
        if _RULE.match(stripped) and i > 0 and "|" in lines[i - 1]:
            header = [c.strip() for c in lines[i - 1].split("|")]
            widths_ok = len(header)
            rows: list[dict[str, str | None]] = []
            j = i + 1
            declared: int | None = None
            while j < len(lines):
                raw = lines[j]
                s = raw.strip()
                m = _ROWCOUNT.match(s)
                if m:
                    declared = int(m.group(1))
                    j += 1
                    break
                if s == "":
                    j += 1
                    break
                cells = [c.strip() for c in raw.split("|")]
                if len(cells) != widths_ok:
                    # Not a data row of this block (e.g. a wrapped note). Stop.
                    break
                rows.append({h: (c if c != "" else None) for h, c in zip(header, cells)})
                j += 1

            if declared is not None and declared != len(rows):
                raise ValueError(
                    f"{path.name} block {len(blocks) + 1}: psql declared {declared} rows, "
                    f"parsed {len(rows)}. Output file may be truncated."
                )
            blocks.append(Block(header, rows, len(blocks) + 1))
            i = j
            continue
        i += 1

    if not blocks:
        raise ValueError(f"{path.name}: no result blocks found")
    return blocks
