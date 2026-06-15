---
name: multi-agent-review
description: >-
  Reviews the current branch diff, a PR, or a spec by fanning it out to multiple
  CLI agents (Codex / Claude / Cursor) in parallel, then merges and ranks their
  findings into one report. Use when the user asks for a multi-agent review,
  "複数エージェントでレビュー", "Rv を並列で", or a cross-check review before merge.
---
# Multi-Agent Review

レビュー対象 (現ブランチ diff / PR / spec) を複数の CLI エージェントへ並列に投げ、各エージェントの指摘を 1 つのレポートに統合・重大度付けする skill。実行エンジンは `agent-orchestrate`、上限/失敗時の挙動 (1 回リトライ後スキップ・部分成功許容) もそれに従う。

## いつ使うか

- 1 つの変更を複数エージェントで相互チェックしてからマージしたい
- 「複数エージェントでレビュー」「Rv を並列で」「クロスレビュー」を要求された
- PR / ブランチ diff / spec を独立した視点で同時にレビューさせたい

## 先に読むもの

- `agent-orchestrate` skill — 並列実行 / 失敗処理 / 集約の基盤 (本 skill の実行エンジン)
- `context/ai-agents.md` — `review` 用途のルーティングとエージェント定義
- `references/review-prompt.md` — レビュープロンプトの組み立て方
- `references/finding-merge.md` — エージェント横断の指摘マージ規則
- `code-review` / `spec-review` skill — 流用するレビュー観点 (rubric)
- `styleguide-documents` skill — 出力レポートの文書品質基準

## 入力

- レビュー対象の指定:
  - 引数なし → 現ブランチ diff (`git diff <base>...HEAD`)
  - PR 番号 / URL → `gh pr diff`
  - spec path → 当該 spec の内容
- 対象エージェント集合 (省略時は `context/ai-agents.md` の `review` ルーティング)
- 出力先 (既定: 標準出力。spec 対象時は任意で `specs/<issue>/reviews/`)

## 実行フロー

### 1. レビュー対象の解決

- 引数から diff / PR / spec を確定する (`references/review-prompt.md`)。
- 差分を取得する (`git diff` または `gh pr diff`)。空なら `停止条件`。

### 2. レビュープロンプトの組み立て

- `references/review-prompt.md` の雛形に、対象差分と rubric 観点 (`code-review` / `spec-review` から流用) を埋め込む。
- 全エージェントへ **同一プロンプト** を渡す (公平な比較のため)。各指摘は `file:line + 重大度 + 根拠 + 提案` で返すよう指示する。

### 3. 並列レビュー実行

- `agent-orchestrate` の並列実行パターンで `review` ルーティングのエージェントへプロンプトを投げる。
- 各エージェントの出力を per-agent ファイルへ収集し、status を分類する (上限は 1 回リトライ後スキップ)。

### 4. 指摘のマージ

- `references/finding-merge.md` の規則で、エージェント横断の指摘を重複排除・統合し、合意数と重大度でランク付けする。
- 単一エージェントのみの指摘は「未合意」として区別する。

### 5. レポート出力

- 統合レポートを提示する: status テーブル → 重大度順の統合指摘 → 各エージェント固有の指摘 → 未合意/相違点。
- spec 対象かつ出力先指定時は `specs/<issue>/reviews/<timestamp>.md` に保存する。
- スキップされたエージェントを明示し、部分結果である旨を断る。

## 停止条件

- レビュー対象が解決できない (diff が空 / PR や spec が見つからない)
- `agent-orchestrate` が成功結果を 1 件も返さなかった (全エージェント上限/失敗)
- `context/ai-agents.md` の `review` ルーティングに `enabled` エージェントが無い

## 禁止事項

- エージェントごとに異なるプロンプトを渡す (比較の公平性が崩れる)
- スキップを伏せて全エージェントがレビューしたかのように報告する
- 指摘の根拠 (`file:line`) を省いてマージする
- CLI 名・モデルを skill に直書きする (`context/ai-agents.md` を読む)
