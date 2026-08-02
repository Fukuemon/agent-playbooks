# PR Workflow

## 作成前チェック

- 現在の branch が作業ブランチである
- 差分が PR タイトル / 本文と一致している
- 関連 Issue と spec のリンクが整理されている
- base branch が `naming.base_branch` (`context/project.yml`) と一致している

## PR 本文に含めること

節の必須 / 任意と見出しの固定は `pr-format.md` の「節の規約」に従う。

- 概要 (必須): この PR で達成したこと
- 背景 (任意): 必要なら背景や制約
- 変更内容 (必須): 主要変更点
- 検証 (必須): 実施内容または未実施理由
- 関連 issue (任意): `Closes` / `Refs`
- 備考 (任意): 残課やレビュー観点

## 本リポジトリ の PR で意識すること

- PRD / Design Doc / feature doc / context / spec / ADR のどこを更新したかを明示する
- app / package 側の実装前提が変わる場合は Notes で伝える

## マージ後 (issue が close したとき)

- 対応する spec (`specs/<issue-id>-*/`) が残っていれば、`spec-lifecycle` の `references/closeout.md` に従い
  sync の取りこぼしゼロを確認して spec を削除する (削除 commit に issue 番号を残す)

## 停止条件

- base branch が `naming.base_branch` 以外 (`release_branch` への直接 PR 等) になっているが、明示指示がない
- `検証` を空欄にしないと本文が作れない (未実施なら理由を書く)
- Related Issues が曖昧で、レビュー単位を追跡できない
