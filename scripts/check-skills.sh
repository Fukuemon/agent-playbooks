#!/usr/bin/env bash
# Skill 共通契約 (AGENTS.md) の機械検査。
# 対象: .rulesync/skills/*/ と skills/*/ (選択導入型) の SKILL.md、.rulesync/subagents/*.md (正本のみ。生成物は見ない)。
# 検査項目:
#   - SKILL.md が存在し 200 行未満
#   - frontmatter の name が directory 名と一致し、description がある
#   - 必須セクション (いつ使うか / 先に読むもの / 実行フロー / 停止条件)
#     ※ reference 型 skill は「先に読むもの / 実行フロー / 停止条件」を省略可
#   - 同義異名セクション (実行手順 / 生成手順 / 終了条件 / ワークフロー) の禁止
#   - references/ は SKILL.md から 1 階層 (サブディレクトリ禁止)
#   - subagent は name がファイル名と一致し、description がある
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 品質基準のみを提供する reference 型 skill (契約の例外)
REFERENCE_TYPE_SKILLS=("styleguide-documents" "effective-go")

fail=0
err() {
  echo "NG: $*" >&2
  fail=1
}

is_reference_type() {
  local name="$1" t
  for t in "${REFERENCE_TYPE_SKILLS[@]}"; do
    [ "$t" = "$name" ] && return 0
  done
  return 1
}

frontmatter_value() { # $1=file $2=key → 値 (先頭の --- 〜 --- ブロック内のみ)
  awk -v key="$2" -F': ' '
    NR == 1 { if ($0 != "---") exit; next }
    /^---$/ { exit }
    $1 == key { sub($1 FS, ""); print; exit }
  ' "$1"
}

for dir in .rulesync/skills/*/ skills/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  f="$dir/SKILL.md"
  if [ ! -f "$f" ]; then
    err "$name: SKILL.md がない"
    continue
  fi

  lines=$(wc -l <"$f" | tr -d ' ')
  [ "$lines" -lt 200 ] || err "$name: SKILL.md が 200 行以上 ($lines 行)。references/ へ分離する"

  fmname="$(frontmatter_value "$f" name)"
  [ "$fmname" = "$name" ] || err "$name: frontmatter name ('$fmname') が directory 名と不一致"

  desc="$(frontmatter_value "$f" description)"
  [ -n "$desc" ] || err "$name: frontmatter description がない"

  grep -q '^## いつ使うか' "$f" || err "$name: 必須セクション「いつ使うか」がない"
  if ! is_reference_type "$name"; then
    for sec in 先に読むもの 実行フロー 停止条件; do
      grep -q "^## $sec" "$f" || err "$name: 必須セクション「$sec」がない"
    done
  fi

  syn="$(grep -nE '^## (実行手順|生成手順|終了条件|ワークフロー)' "$f" || true)"
  [ -z "$syn" ] || err "$name: 同義異名セクションを使っている → $syn (正規名: 実行フロー / 停止条件)"

  if [ -d "$dir/references" ]; then
    deep="$(find "$dir/references" -mindepth 1 -type d || true)"
    [ -z "$deep" ] || err "$name: references/ にサブディレクトリがある (1 階層のみ許可): $deep"
  fi
done

for f in .rulesync/subagents/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .md)"
  fmname="$(frontmatter_value "$f" name)"
  [ "$fmname" = "$base" ] || err "subagent $base: frontmatter name ('$fmname') がファイル名と不一致"
  desc="$(frontmatter_value "$f" description)"
  [ -n "$desc" ] || err "subagent $base: frontmatter description がない"
done

if [ "$fail" -ne 0 ]; then
  echo "check-skills: 契約違反あり (正本は AGENTS.md の Skill 共通契約)" >&2
  exit 1
fi
echo "check-skills: OK"
