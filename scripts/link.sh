#!/usr/bin/env bash
# Link this sdd-template's shared process layer into a consumer repo via symlinks.
#
# Why: the development-process assets (skills + operating contract + hooks) are
# generic. Instead of copying them into every product repo (which drifts), we
# symlink the LIVE source here so editing either side updates both. The consumer
# then runs `rulesync generate` to emit provider configs from the symlinked input.
#
# This template keeps `.rulesync/` as the single source of truth (no dist build),
# so unlike the dist-based reference model we link the live tree directly and do
# NOT make it read-only — bidirectional editing is the whole point.
#
# Product-specific values stay OWNED by the consumer and are never symlinked:
#   context/ (project.md etc.), PRD.md, design/, specs/, adr/.
#
# Run from anywhere:  bash scripts/link.sh <consumer-repo-path>
# Idempotent. Re-run after adding/removing skills to refresh links.
set -euo pipefail

TEMPLATE_DIR="${TEMPLATE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

CONSUMER="${1:-}"
if [ -z "$CONSUMER" ]; then
  read -r -p "接続先 (消費 repo) のパス: " CONSUMER
fi
[ -n "$CONSUMER" ] || { echo "ERROR: 消費 repo のパスを指定してください" >&2; exit 1; }
[ -d "$CONSUMER" ] || { echo "ERROR: パスが存在しません: $CONSUMER" >&2; exit 1; }
CONSUMER="$(cd "$CONSUMER" && pwd)"
git -C "$CONSUMER" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "ERROR: git repo ではありません: $CONSUMER" >&2; exit 1; }

if [ "$CONSUMER" = "$TEMPLATE_DIR" ]; then
  echo "ERROR: テンプレ自身には link できません" >&2; exit 1
fi

# --- 共有プロセス層 (symlink 対象) を組み立てる -----------------------------
# 固定パス + `.rulesync/skills/*` を動的に列挙する。
# `context/` (project.md 等) / PRD.md / design/ / specs/ / adr/ は消費 repo 所有 = symlink しない。
# permissions.json / mcp.json は汎用デフォルトとして共有する。製品固有にしたい場合は
# 消費側で symlink を実ファイルに置き換える (link.sh 再実行で上書きされない: backup される)。
CANDIDATES=(
  "rulesync.jsonc"
  ".rulesync/rules/CLAUDE.md"
  ".rulesync/hooks.json"
  ".rulesync/permissions.json"
  ".rulesync/mcp.json"
  ".rulesync/.aiignore"
  ".rulesync/subagents"
  "scripts/link.sh"
  "scripts/fix-cursor-cli.sh"
  "hooks"
)
for skill in "$TEMPLATE_DIR"/.rulesync/skills/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  CANDIDATES+=(".rulesync/skills/$name")
done

LINKED=()
BACKED_UP=()
TRACKED_WARN=()

for rel in "${CANDIDATES[@]}"; do
  src="$TEMPLATE_DIR/$rel"
  [ -e "$src" ] || { echo "  skip (source 無し): $rel"; continue; }
  dst="$CONSUMER/$rel"
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    rm -f "$dst"                                   # 既存 symlink は安全置換
  elif [ -e "$dst" ]; then
    if git -C "$CONSUMER" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
      TRACKED_WARN+=("$rel")                       # tracked 実体は消さず警告
      rm -rf "$dst"
    else
      mv "$dst" "$dst.pre-link.bak"                # 未追跡実体は退避
      BACKED_UP+=("$rel")
    fi
  fi
  ln -sfn "$src" "$dst"
  LINKED+=("$rel")
  echo "  link: $rel"
done

# --- .git/info/exclude に管理ブロックを設置 (commit しない) ------------------
EXCLUDE="$(git -C "$CONSUMER" rev-parse --git-path info/exclude)"
case "$EXCLUDE" in /*) ;; *) EXCLUDE="$CONSUMER/$EXCLUDE" ;; esac
BEGIN="# >>> sdd-template: linked AI config (managed by scripts/link.sh; do not edit this block) >>>"
END="# <<< sdd-template: linked AI config <<<"
mkdir -p "$(dirname "$EXCLUDE")"

# 既存 exclude から管理ブロックを除いた本体を取り出す
BODY=""
if [ -e "$EXCLUDE" ]; then
  BODY="$(awk -v b="$BEGIN" -v e="$END" '
    $0==b {skip=1; next}
    skip && $0==e {skip=0; next}
    skip {next}
    {print}
  ' "$EXCLUDE")"
fi
{
  [ -n "$BODY" ] && printf '%s\n' "$BODY"
  printf '%s\n' "$BEGIN"
  printf '# sdd-template への symlink (per-clone)。commit しない。link.sh 再実行で復元。\n'
  for rel in "${LINKED[@]}"; do printf '/%s\n' "$rel"; done
  printf '%s\n' "$END"
} >"$EXCLUDE"
echo "  exclude: $EXCLUDE に管理ブロックを設置 (${#LINKED[@]} entries)"

# --- 後始末ガイド -----------------------------------------------------------
echo ""
echo "── 完了 ───────────────────────────────────────────────"
if [ "${#BACKED_UP[@]}" -gt 0 ]; then
  echo "NOTE: 未追跡の既存ファイルを *.pre-link.bak に退避しました:"
  printf '  %s.pre-link.bak\n' "${BACKED_UP[@]}"
fi
if [ "${#TRACKED_WARN[@]}" -gt 0 ]; then
  echo "WARN: 次のパスは git に commit 済みです。一度 untrack してください:"
  printf '  git -C "%s" rm -r --cached %s\n' "$CONSUMER" "${TRACKED_WARN[*]}"
fi
cat <<EOF

次のステップ (消費 repo 側で実行):
  cd "$CONSUMER"
  npx rulesync@latest generate && bash scripts/fix-cursor-cli.sh

固有値 (symlink されない / 消費 repo が所有):
  context/ (project.md 等), PRD.md, design/, specs/, adr/
  → 実ファイルとして記入・commit する。

双方向更新: 共有 skill / contract / hook は live symlink。どちらの repo で編集しても
両方に反映される。
EOF
