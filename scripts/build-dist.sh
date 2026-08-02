#!/usr/bin/env bash
# .rulesync/ から生成した provider 設定を dist/ へ集約する。
# dist/ は消費 repo の symlink 先。中央で 1 回生成し、消費 repo では生成しない。
#
# 生成そのものは scripts/generate.sh に集約されている (唯一の生成シーケンス)。
# 本スクリプトはその出力を dist/ へ写すだけ。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 消費 repo へ配る生成物。テンプレ repo 自身もこれらを root に持つ (自分で使うため)。
ARTIFACTS=(
  "CLAUDE.md"
  "AGENTS.md"
  ".mcp.json"
  ".claude"
  ".codex"
  ".cursor"
  ".agents"
)

bash "$ROOT/scripts/generate.sh"

rm -rf "$ROOT/dist"
mkdir -p "$ROOT/dist"
for rel in "${ARTIFACTS[@]}"; do
  [ -e "$ROOT/$rel" ] || { echo "  skip (生成されていない): $rel"; continue; }
  cp -R "$ROOT/$rel" "$ROOT/dist/$rel"
  echo "  dist: $rel"
done
echo "build-dist: dist/ を更新しました"
