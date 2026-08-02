#!/usr/bin/env bash
# .rulesync/ から各 provider 設定を生成し、provider 別 normalizer を適用する。
# 唯一の生成シーケンス。scripts/build-dist.sh が本スクリプトを呼ぶ
# (手動列挙による同期漏れを防ぐ)。
# 冪等なので何度実行してもよい。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# バージョンは pin する (@latest だと上流リリースで生成物が変わり、repo 側の変更なしに
# drift 検査が壊れる)。更新は動作確認のうえ本行の bump commit で行う。
npx rulesync@14.2.0 generate
bash "$ROOT/scripts/fix-cursor-cli.sh"
bash "$ROOT/scripts/fix-codex-config.sh"
bash "$ROOT/scripts/fix-claude-settings.sh"

# 生成直後に formatter を適用し、生成 = 最終形にする。ここで揃えないと
# pre-commit (prettier) 適用後の commit 内容と生成直後の出力がズレ、
# drift 検査 (check-dist) が無関係な変更でも差分を出す。
# バージョンは hooks/format/run_prettier.sh の pin と揃える。
TARGETS=()
for p in CLAUDE.md AGENTS.md .mcp.json .claude .codex .cursor .agents; do
  [ -e "$p" ] && TARGETS+=("$p")
done
if [ "${#TARGETS[@]}" -gt 0 ]; then
  if [ -x "node_modules/.bin/prettier" ]; then
    node_modules/.bin/prettier --write --ignore-unknown --log-level warn "${TARGETS[@]}"
  else
    npx --yes prettier@3.6.2 --write --ignore-unknown --log-level warn "${TARGETS[@]}"
  fi
fi
