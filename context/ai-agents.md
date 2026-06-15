# AI Agents Registry

> 最終更新: 2026-06-15

非対話で呼び出せる CLI エージェント (Codex / Claude / Cursor 等) の **唯一の正本**。`agent-orchestrate` / `multi-agent-review` skill は、CLI 名・モデル・flag をハードコードせず本ファイルを読む。スキーマの説明は `agent-orchestrate/references/agent-registry-schema.md` を参照する。

<!--
記入ガイド:
- 各エージェントは 1 つの `### <id>` ブロックで定義する。
- `invocation` はプロンプトを `$PROMPT` プレースホルダで受ける **非対話** コマンド。実行前に各 CLI の `--help` で flag を確定し、確認できたら `verified: yes` にする。
- `limit_patterns` は exit code か stdout/stderr に現れる文字列。token/rate 上限を検知するために使う。
- 値を変えたら先頭の「最終更新」を更新する。
-->

## 共通既定

- 出力先 dir 既定: `.ai-out/agent-runs/<timestamp>/` (per-agent ファイル `<id>.out` / `<id>.exit` を置く)
- timeout 既定: 600 秒 (各ブロックで上書き可)
- timeout runner: GNU `timeout` (macOS では未搭載のため `gtimeout` / coreutils へフォールバック。`parallel-execution.md` 参照)
- stdin: 各エージェントは `</dev/null` で起動する (stdin 待ちハング防止)
- `max_input_tokens` 既定: 120k (各ブロックで上書き可。超える差分は `multi-agent-review` 側で chunk 分割)
- 上限/失敗時ポリシー: **1 回リトライ後スキップ・部分成功許容** (`failure-handling.md` 参照)

## エージェント定義

### claude

- `enabled`: yes
- `model`: (CLI 既定)
- `invocation`: `claude -p "$PROMPT" --output-format text`
- `verified`: yes <!-- 2026-06-15 multi-agent-review 実行で確認 (`</dev/null` 起動必須) -->
- `limit_patterns`: `usage limit`, `rate limit`, `429`
- `auth_note`: ログイン済み or `ANTHROPIC_API_KEY`
- `timeout`: 600

### codex

- `enabled`: yes
- `model`: (CLI 既定)
- `invocation`: `codex exec "$PROMPT"`
- `verified`: yes <!-- 2026-06-15 確認。stdin パイプ誤検知でハングするため `</dev/null` 起動必須 -->
- `limit_patterns`: `rate limit`, `quota`, `usage limit`, `429`
- `auth_note`: `codex login` 済み or API key
- `timeout`: 600

### cursor

- `enabled`: yes
- `model`: `composer-2.5`
- `invocation`: `agent --print --model composer-2.5 --output-format text "$PROMPT"`
- `verified`: no <!-- 2026-06-15 `.cursor/cli.json` の schema validation 失敗で起動不可。後述「既知の問題」参照 -->
- `limit_patterns`: `rate limit`, `usage limit`, `quota`, `429`
- `auth_note`: `cursor` / `agent` CLI でログイン済み
- `timeout`: 600

## 用途別ルーティング

| 用途        | 既定で使うエージェント  | 備考                       |
| ----------- | ----------------------- | -------------------------- |
| review (Rv) | claude, codex, cursor   | 並列レビュー → 指摘マージ  |
| implement   | cursor (`composer-2.5`) | 実装委譲。完了後に検証する |

- フォールバックは既定では行わず、上限/失敗エージェントはスキップして残りで続行する。
- 用途ごとに使うエージェントを変える場合は skill 起動時に上書き指定する。

## 既知の問題

- **cursor (`agent`) 起動不可 (2026-06-15)**: 生成された `.cursor/cli.json` が cursor CLI の schema validation に失敗する (`permissions.deny` 必須欠落 / 未知キー `version`・`editor`)。`review` ルーティングで cursor は当面スキップされる。`rulesync` 生成出力と cursor CLI のスキーマ差が原因のため、`rulesync` のバージョン更新で再生成して解消するか、`.rulesync/permissions.json` 側の表現を調整する。`implement` ルーティングも cursor 依存のため影響する。
