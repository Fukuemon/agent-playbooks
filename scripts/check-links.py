#!/usr/bin/env python3
"""Markdown の相対リンクを 2 つの観点で検査する。

A. skill の外を指すリンクの禁止
   skill は `.rulesync/skills/<name>/` から各 provider の配置先
   (`.claude/skills/<name>/` 等) へコピーされるため階層が変わる。
   skill ディレクトリの外を指す相対リンクはコピー後に解決しなくなる。
   実際に spec-requirement で 6 件切れていた (2026-08-02)。
   外を指すときは markdown リンクにせず、バッククォートで path を書く。

B. 追跡ファイルの相対リンクが実在すること

除外するもの:
  .rulesync/rules/  リンクは配置先 (消費 repo のルート) からの相対 path
  templates/        リンクはテンプレの配置先からの相対 path
  dist/ .claude/ .codex/ .cursor/ .agents/  生成物 (正本を直せば直る)
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

SKILL_ROOTS = (".rulesync/skills", "skills")
# 生成物。正本 (.rulesync/rules/) を直せば直る。
EXCLUDE_FILES = ("AGENTS.md", "CLAUDE.md")

# 消費 repo だけが持つ path。テンプレ repo には実在しないが、
# テンプレの文書が消費 repo の構成を説明するために参照する。
CONSUMER_ONLY = ("PRD.md", "specs")

EXCLUDE_PREFIXES = (
    ".rulesync/rules/",
    "templates/",
    "dist/",
    ".claude/",
    ".codex/",
    ".cursor/",
    ".agents/",
)

FENCE_RE = re.compile(r"```.*?```", re.S)
SPAN_RE = re.compile(r"`[^`\n]*`")
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)\s]+)\)")


def repo_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parent.parent


def tracked_markdown(root: pathlib.Path) -> list[str]:
    out = subprocess.run(
        ["git", "-C", str(root), "ls-files", "*.md"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return sorted(out.splitlines())


def links(path: pathlib.Path) -> list[tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    text = FENCE_RE.sub("", text)
    text = SPAN_RE.sub("", text)
    found = []
    for m in LINK_RE.finditer(text):
        target = m.group(2).split("#")[0].strip()
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        found.append((m.group(1), target))
    return found


def skill_dir_of(rel: str) -> str | None:
    """`.rulesync/skills/<name>/...` なら `<name>` までの path を返す。"""
    for root in SKILL_ROOTS:
        prefix = root + "/"
        if rel.startswith(prefix):
            rest = rel[len(prefix) :]
            name = rest.split("/", 1)[0]
            return f"{root}/{name}"
    return None


def main() -> int:
    root = repo_root()
    problems = 0

    for rel in tracked_markdown(root):
        path = root / rel
        skill = skill_dir_of(rel)

        for label, target in links(path):
            resolved = (path.parent / target).resolve()

            if skill is not None:
                # A: skill の外を指していないか (実在するかどうかとは別に見る)
                try:
                    resolved.relative_to((root / skill).resolve())
                except ValueError:
                    print(f"NG {rel}: skill の外を指すリンク [{label}]({target})")
                    print("   → markdown リンクにせず、バッククォートで path を書く")
                    problems += 1
                    continue

            if rel.startswith(EXCLUDE_PREFIXES) or rel in EXCLUDE_FILES:
                continue

            try:
                target_rel = resolved.relative_to(root).as_posix()
            except ValueError:
                target_rel = ""
            if target_rel in CONSUMER_ONLY or target_rel.startswith("specs/"):
                continue

            # B: 参照先が実在するか
            if not resolved.exists():
                print(f"NG {rel}: [{label}]({target})")
                problems += 1

    if problems:
        print(f"\ncheck-links: {problems} 件", file=sys.stderr)
        return 1
    print("check-links: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
