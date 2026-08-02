#!/usr/bin/env bash
# dist/ が .rulesync/ と同期しているかを検査する。
# 再生成して git diff が出れば drift とみなす (scripts/depgraph.sh と同じ形)。
#
# 終了コード: 0 検査 OK / 1 drift あり / 2 検査不能 (生成に失敗)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! bash "$ROOT/scripts/build-dist.sh" >/dev/null 2>&1; then
  echo "NG: scripts/build-dist.sh が失敗しました (npx / ネットワークを確認)" >&2
  exit 2
fi

if ! git diff --quiet -- dist; then
  echo "NG: dist/ が .rulesync/ と drift しています (再生成で差分が出ました):" >&2
  git --no-pager diff --stat -- dist >&2
  echo "→ 再生成の結果をコミットしてください (make dist)" >&2
  exit 1
fi

echo "check-dist: OK"
