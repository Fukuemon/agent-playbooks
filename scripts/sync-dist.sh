#!/usr/bin/env bash
# 配布専用 worktree (<repo>/.wt/dist) を SDD_DIST_REF (既定 origin/main) に合わせ直す。
# 消費 repo の symlink はこの worktree を指すため、link 済みの全 repo が同時に更新される。
#
# 未 merge のブランチを指したまま消費 repo を動かすと、レビューを通っていない
# 契約でエージェントが動く。ref を push 済みの位置に固定するのはそのため。
#
# 環境変数で上書き可: SDD_DIR / SDD_WORKTREE / SDD_DIST_REF
set -euo pipefail

SDD_DIR="${SDD_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SDD_WORKTREE="${SDD_WORKTREE:-${SDD_DIR}/.wt/dist}"
SDD_DIST_REF="${SDD_DIST_REF:-origin/main}"

command -v git >/dev/null 2>&1 || { echo "ERROR: git が必要です" >&2; exit 1; }

git -C "$SDD_DIR" fetch --quiet origin \
  || echo "WARN: fetch 失敗。ローカルの $SDD_DIST_REF を使います (stale の可能性)。" >&2

if [ -e "$SDD_WORKTREE/.git" ] || git -C "$SDD_DIR" worktree list --porcelain | grep -qx "worktree $SDD_WORKTREE"; then
  before="$(git -C "$SDD_WORKTREE" rev-parse --short HEAD 2>/dev/null || echo '?')"
  chmod -R u+w "$SDD_WORKTREE" 2>/dev/null || true
  git -C "$SDD_WORKTREE" reset --hard --quiet "$SDD_DIST_REF"
  git -C "$SDD_WORKTREE" clean -fdq
else
  before="(新規作成)"
  git -C "$SDD_DIR" worktree prune
  git -C "$SDD_DIR" worktree add --force --detach "$SDD_WORKTREE" "$SDD_DIST_REF" >/dev/null
fi

# symlink 経由の誤書き込みを OS で止める。消費 repo で編集したつもりが
# 配布物を書き換えていた、という事故を防ぐ。
for ro in dist hooks templates; do
  [ -d "$SDD_WORKTREE/$ro" ] && chmod -R a-w "$SDD_WORKTREE/$ro" 2>/dev/null || true
done

after="$(git -C "$SDD_WORKTREE" rev-parse --short HEAD)"
echo "worktree: $SDD_WORKTREE"
echo "更新: $before -> $after ($SDD_DIST_REF)"
