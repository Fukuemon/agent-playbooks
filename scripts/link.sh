#!/usr/bin/env bash
# sdd-template の共有プロセス層を消費 repo へ接続する。配布は 3 層:
#
#   1. 生成物 (CLAUDE.md / .claude 等) と .rulesync = symlink (未追跡)。
#      生成は中央 (本 repo の `make dist`) で 1 回だけ行い、更新は `make sync` で
#      全消費 repo に同時反映される。
#   2. hooks/ / templates/ = 実ファイルの上書き配布 (消費 repo が commit する)。
#      commit 済み lefthook.yml が実行時に hooks/ を参照するため、clone しただけの
#      環境にも実在させる。編集はテンプレ側のみ。判断は decisions.md 2026-08-03。
#   3. 消費 repo 所有の初期値 (lefthook.yml / workflow 等) = 無い場合だけコピー。
#
# 代償: link.sh を実行していない環境 (CI / cloud agent / 新規 clone) には
# AI 設定 (symlink 層) が存在しない。この判断は decisions.md 2026-08-02 を見る。
# 欠落を silent にしないため、消費 repo では `bash scripts/doctor.sh` で検査する。
#
# symlink 先は SDD_DIST_REF (既定 origin/main) に固定した worktree (<repo>/.wt/dist)。
# 未 merge のブランチを指したまま消費 repo を動かさないための固定である。
#
# プロダクト固有値は消費 repo の所有物であり、共有しない:
#   context/ (project.yml など)、PRD.md、design/、specs/、adr/。
#
# 実行 (どこからでも可):  bash scripts/link.sh <consumer-repo-path>
# 冪等。更新は `make sync` (worktree を origin/main へ) で全消費 repo に同時反映される。
set -euo pipefail

TEMPLATE_DIR="${TEMPLATE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SDD_WORKTREE="${SDD_WORKTREE:-${TEMPLATE_DIR}/.wt/dist}"
SDD_DIST_REF="${SDD_DIST_REF:-origin/main}"

CONSUMER="${1:-}"
if [ -z "$CONSUMER" ]; then
  [ -t 0 ] || { echo "ERROR: 非対話実行ではパス引数が必須です: bash scripts/link.sh <consumer-repo-path>" >&2; exit 1; }
  read -r -p "接続先 (消費 repo) のパス: " CONSUMER
fi
[ -n "$CONSUMER" ] || { echo "ERROR: 消費 repo のパスを指定してください" >&2; exit 1; }
[ -d "$CONSUMER" ] || { echo "ERROR: パスが存在しません: $CONSUMER" >&2; exit 1; }
CONSUMER="$(cd "$CONSUMER" && pwd)"
git -C "$CONSUMER" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "ERROR: git repo ではありません: $CONSUMER" >&2; exit 1; }
[ "$CONSUMER" != "$TEMPLATE_DIR" ] || { echo "ERROR: テンプレ自身には link できません" >&2; exit 1; }

echo "接続先: $CONSUMER"
echo "ref:    $SDD_DIST_REF"

# --- 1) 配布 worktree を用意/更新 -------------------------------------------
# SDD_SKIP_SYNC=1 で省略できる。git worktree を作るたびに fetch すると重いため、
# 既に用意済みの配布 worktree へ張り直すだけの経路で使う。
if [ "${SDD_SKIP_SYNC:-0}" = "1" ] && [ -d "$SDD_WORKTREE/dist" ]; then
  echo "sync: skip (SDD_SKIP_SYNC=1)"
else
  SDD_DIR="$TEMPLATE_DIR" SDD_WORKTREE="$SDD_WORKTREE" SDD_DIST_REF="$SDD_DIST_REF" \
    bash "$TEMPLATE_DIR/scripts/sync-dist.sh"
fi

DIST="$SDD_WORKTREE/dist"
[ -d "$DIST" ] || { echo "ERROR: $DIST が無い (中央で make dist して push したか確認)" >&2; exit 1; }

# --- 2) symlink を張る -------------------------------------------------------
# `.claude` / `.codex` などは丸ごとではなく配下を個別に張る。消費 repo が
# 独自の設定ファイルを同じ階層に置けるようにするため。
# hooks/ / templates/ は symlink ではなく実ファイルの上書き配布 (下の 2.5)。
CANDIDATES=(
  "CLAUDE.md" "AGENTS.md" ".mcp.json"
  ".rulesync"
)
for d in "$DIST"/.claude/* "$DIST"/.codex/* "$DIST"/.cursor/* "$DIST"/.agents/*; do
  [ -e "$d" ] || continue
  CANDIDATES+=("${d#"$DIST"/}")
done

# 前回の link で張ったが今回の配布物に無くなった symlink を先に外す。
# 残っていると、配布単位を細かくしたとき (templates/ → templates/<sub>) に
# 親の symlink 越しに read-only な worktree を触りに行って失敗する。
PREV_EXCLUDE="$(git -C "$CONSUMER" rev-parse --git-path info/exclude)"
[ "${PREV_EXCLUDE#/}" = "$PREV_EXCLUDE" ] && PREV_EXCLUDE="$CONSUMER/$PREV_EXCLUDE"
if [ -f "$PREV_EXCLUDE" ]; then
  while IFS= read -r prev; do
    prev="${prev#/}"
    [ -n "$prev" ] || continue
    case " ${CANDIDATES[*]} " in *" $prev "*) continue ;; esac
    if [ -L "$CONSUMER/$prev" ]; then
      rm -f "$CONSUMER/$prev"
      echo "  unlink (配布対象外になった): $prev"
    fi
  done < <(sed -n '/^# BEGIN sdd-template link$/,/^# END sdd-template link$/p' "$PREV_EXCLUDE" | grep '^/' || true)
fi

LINKED=()
BACKED_UP=()
TRACKED_WARN=()
for rel in "${CANDIDATES[@]}"; do
  case "$rel" in
    .rulesync) src="$TEMPLATE_DIR/.rulesync" ;; # 著作用。worktree ではなく作業 clone を指す
    *) src="$DIST/$rel" ;;
  esac
  [ -e "$src" ] || { echo "  skip (source 無し): $rel"; continue; }

  dst="$CONSUMER/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    if git -C "$CONSUMER" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
      # 旧方式で commit 済み。置換して移行案内に集める (削除の確定は消費側の commit)。
      TRACKED_WARN+=("$rel")
      rm -rf "$dst"
    else
      # 未追跡の実体は消費 repo 固有の可能性がある。無言で消さず退避する。
      mv "$dst" "$dst.pre-link.bak"
      BACKED_UP+=("$rel")
    fi
  fi
  ln -sfn "$src" "$dst"
  LINKED+=("$rel")
done
echo "  link: ${#LINKED[@]} entries"

# --- 2.5) hooks / templates は実ファイルの上書き配布 (消費 repo が commit する) --
# commit 済みの lefthook.yml が実行時に hooks/ を参照するため、clone しただけの
# 環境 (CI / cloud agent / 共同開発者) にも実在させる。編集はテンプレ側でのみ行い、
# link のたびに worktree (origin/main 固定) の版で上書きする (上書き = 権威の強制)。
# 消費側に差分があれば無言で巻き戻さず、必ず一覧で報告する (issue #11 の教訓)。
# ファイル単位でコピーし、同じディレクトリの自前ファイル
# (例: hooks/format/run_oxfmt.sh, templates/consumers/) には触らない。
# templates/consumer/ はテンプレ内部のもの (消費 repo 所有ファイルの初期値) なので配らない。
# git worktree には消費 repo の commit 経由で届くため、メイン worktree でのみコピーする。
OVERWRITTEN=()
MAIN_WT="$(git -C "$CONSUMER" worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
if [ "$MAIN_WT" = "$CONSUMER" ]; then
  copied=0
  while IFS= read -r src; do
    rel="${src#"$SDD_WORKTREE"/}"
    dst="$CONSUMER/$rel"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ] && ! cmp -s "$src" "$dst"; then
      # commit 済みでクリーンなら旧版は git history にあるため退避不要。
      # 未追跡・未 commit の差分は上書きで失われるので退避する。
      if ! git -C "$CONSUMER" ls-files --error-unmatch "$rel" >/dev/null 2>&1 \
        || ! git -C "$CONSUMER" diff --quiet -- "$rel" 2>/dev/null; then
        cp -p "$dst" "$dst.pre-link.bak"
        BACKED_UP+=("$rel")
      fi
      OVERWRITTEN+=("$rel")
    fi
    # 旧 symlink・read-only な既存実体のどちらも rm してから置く (cp 直書きは
    # read-only な dst で失敗する)。worktree 由来の read-only は引き継がず、
    # 消費側 formatter 等が詰まらないよう owner 書き込み可へ正規化する。
    rm -f "$dst"
    cp -p "$src" "$dst"
    chmod u+w "$dst"
    copied=$((copied + 1))
  done < <({
    find "$SDD_WORKTREE/hooks" -type f 2>/dev/null
    find "$SDD_WORKTREE/templates" -type f -not -path "*/templates/consumer/*" 2>/dev/null
  } | sort)
  echo "  copy (上書き配布): hooks/ templates/ — ${copied} files"
fi

# --- 3) ignore は消費 clone の .git/info/exclude へ (commit されない) ---------
EXCLUDE="$(git -C "$CONSUMER" rev-parse --git-path info/exclude)"
[ "${EXCLUDE#/}" = "$EXCLUDE" ] && EXCLUDE="$CONSUMER/$EXCLUDE"
mkdir -p "$(dirname "$EXCLUDE")"
BEGIN="# BEGIN sdd-template link"
END="# END sdd-template link"
{
  [ -f "$EXCLUDE" ] && sed "/^${BEGIN}$/,/^${END}$/d" "$EXCLUDE" || true
  echo "$BEGIN"
  printf '/%s\n' ${LINKED[@]+"${LINKED[@]}"}
  echo "$END"
} >"$EXCLUDE.tmp"
mv "$EXCLUDE.tmp" "$EXCLUDE"
echo "  exclude: $EXCLUDE に ${#LINKED[@]} entries"

# --- 4) 消費 repo が所有するファイルの初期値 ---------------------------------
# 一度置いたら消費 repo の所有物になるもの。上書きすると独自の変更を silent に壊す。
for rel in "lefthook.yml" ".prettierignore" ".github/workflows/spec-closeout.yml" ".github/workflows/spec-residue.yml" "scripts/check-specs-residue.sh" "scripts/doctor.sh" "scripts/link-worktree.sh"; do
  src="$TEMPLATE_DIR/templates/consumer/$rel"
  [ -e "$src" ] || src="$TEMPLATE_DIR/$rel"
  [ -e "$src" ] || continue
  if [ ! -e "$CONSUMER/$rel" ]; then
    mkdir -p "$(dirname "$CONSUMER/$rel")"
    cp "$src" "$CONSUMER/$rel"
    case "$rel" in *.sh) chmod +x "$CONSUMER/$rel" ;; esac
    echo "  copy: $rel (初期値。以後は消費 repo が所有)"
  fi
done

# --- 5) 消費 repo の他の worktree へも張る -----------------------------------
# symlink は追跡されないため、git worktree を作っても配布物が 1 つも来ない。
# 既存の worktree はここで面倒を見る (新規作成分は lefthook の post-checkout)。
if [ "${SDD_LINK_WORKTREES:-1}" = "1" ]; then
  while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    [ "$wt" = "$CONSUMER" ] && continue
    [ -d "$wt" ] || continue
    echo
    echo "worktree へ展開: $wt"
    SDD_SKIP_SYNC=1 SDD_LINK_WORKTREES=0 bash "$TEMPLATE_DIR/scripts/link.sh" "$wt" \
      | sed 's/^/  /'
  done < <(git -C "$CONSUMER" worktree list --porcelain | awk '/^worktree /{print $2}')
fi

echo
echo "link done (worktree=$SDD_WORKTREE)"
if [ "${#TRACKED_WARN[@]}" -gt 0 ]; then
  echo
  echo "旧方式で commit されていた生成物を symlink へ置き換えました。untrack してください:"
  printf '  git rm -r --cached %s\n' ${TRACKED_WARN[@]+"${TRACKED_WARN[@]}"}
  echo "  git commit -m 'chore(sdd): 共有プロセス層を symlink 配布へ移行し生成物を untrack する'"
fi
if [ "${#OVERWRITTEN[@]}" -gt 0 ]; then
  echo
  echo "テンプレ版で上書きしたファイル (消費側に差分があった)。意図した変更ならテンプレへ還元すること:"
  printf '  %s\n' ${OVERWRITTEN[@]+"${OVERWRITTEN[@]}"}
  echo "  差分の確認: git -C $CONSUMER diff -- hooks templates"
fi
if [ "${#BACKED_UP[@]}" -gt 0 ]; then
  echo
  echo "未追跡・未 commit の実体を退避しました (*.pre-link.bak)。不要なら削除してください:"
  printf '  %s.pre-link.bak\n' ${BACKED_UP[@]+"${BACKED_UP[@]}"}
fi
echo
echo "検査: cd $CONSUMER && bash scripts/doctor.sh"
