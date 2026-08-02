#!/usr/bin/env bash
# 生成物 (repo root の AGENTS.md / CLAUDE.md / .claude/ 等) と dist/ が
# .rulesync/ と同期しているかを検査する。
# 再生成して git diff が出れば drift とみなす。
#
# 旧 check-generated.sh を統合した。build-dist.sh が generate.sh を呼ぶため、
# 1 回の再生成で root と dist の両方を検査できる。
#
# 終了コード: 0 検査 OK / 1 drift あり / 2 検査不能 (生成に失敗)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! bash "$ROOT/scripts/build-dist.sh" >/dev/null 2>&1; then
  echo "NG: scripts/build-dist.sh が失敗しました (npx / ネットワークを確認)" >&2
  exit 2
fi

TARGETS=(dist CLAUDE.md AGENTS.md .mcp.json .claude .codex .cursor .agents)

if ! git diff --quiet -- "${TARGETS[@]}"; then
  echo "NG: 生成物が .rulesync/ と drift しています (再生成で差分が出ました):" >&2
  git --no-pager diff --stat -- "${TARGETS[@]}" >&2
  echo "→ 再生成の結果をコミットしてください (make dist)" >&2
  exit 1
fi

untracked="$(git ls-files --others --exclude-standard -- "${TARGETS[@]}")"
if [ -n "$untracked" ]; then
  echo "NG: 未コミットの生成物があります:" >&2
  echo "$untracked" >&2
  exit 1
fi

echo "check-dist: OK"
