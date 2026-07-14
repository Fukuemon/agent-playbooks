#!/usr/bin/env bash
# 生成物 drift 検査: .rulesync/ (正本) から再生成し、実行前後で差分がないことを確認する。
# 生成物がズレたまま配られると、消費 repo / 各 provider に古い設定が silent に届くため、CI の硬いゲートにする。
# 注意: 実行するとローカルの生成物を再生成する (同期済みなら no-op)。
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GENERATED_PATHS=(AGENTS.md CLAUDE.md .agents .claude .codex .cursor .mcp.json)

before="$(mktemp -d)"
trap 'rm -rf "$before"' EXIT
for path in "${GENERATED_PATHS[@]}"; do
  [ -e "$path" ] || continue
  mkdir -p "$before/$(dirname "$path")"
  cp -R "$path" "$before/$path"
done

npx rulesync@latest generate
bash scripts/fix-cursor-cli.sh
bash scripts/fix-codex-config.sh
bash scripts/fix-claude-settings.sh

drift=0
for path in "${GENERATED_PATHS[@]}"; do
  if ! diff -qr "$before/$path" "$path" >/dev/null 2>&1; then
    echo "NG: 再生成で差分が出ました: $path" >&2
    diff -qr "$before/$path" "$path" >&2 || true
    drift=1
  fi
done

if [ "$drift" -ne 0 ]; then
  echo "→ 'make generate' を実行し、生成結果を確認してください (rulesync-sync skill)" >&2
  exit 1
fi
echo "check-generated: OK"
