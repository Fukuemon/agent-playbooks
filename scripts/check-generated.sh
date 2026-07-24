#!/usr/bin/env bash
# 生成物 drift 検査: .rulesync/ (正本) から再生成し、コミット済み生成物と差分がないことを確認する。
# 生成物がズレたまま配られると、消費 repo / 各 provider に古い設定が silent に届くため、CI の硬いゲートにする。
# 注意: 実行するとローカルの生成物を再生成する (同期済みなら no-op)。
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GENERATED_PATHS=(AGENTS.md CLAUDE.md .agents .claude .codex .cursor .mcp.json)

bash scripts/generate.sh

drift=0
if ! git diff --quiet HEAD -- "${GENERATED_PATHS[@]}"; then
  echo "NG: 生成物が .rulesync/ と drift しています (再生成で差分が出ました):" >&2
  git --no-pager diff --stat -- "${GENERATED_PATHS[@]}" >&2
  drift=1
fi

untracked="$(git ls-files --others --exclude-standard -- "${GENERATED_PATHS[@]}")"
if [ -n "$untracked" ]; then
  echo "NG: 未コミットの生成物があります:" >&2
  echo "$untracked" >&2
  drift=1
fi

if [ "$drift" -ne 0 ]; then
  echo "→ .rulesync/ を編集したら 'make generate' の結果もコミットしてください (rulesync-sync skill)" >&2
  exit 1
fi
echo "check-generated: OK"
