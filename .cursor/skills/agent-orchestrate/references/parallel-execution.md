# Parallel Execution

複数エージェントを非対話・並列に起動し、結果を per-agent ファイルへ収集する正準パターン。

## 原則

- 各エージェントを background (`&`) で起動し、`wait` で全完了を待つ。
- 出力は **エージェントごとに別ファイル** へ分離する (混線を防ぐ)。
- 各エージェントに `timeout` を掛け、ハングで全体が止まらないようにする。
- 終了コードを `<id>.exit` に保存し、後段の失敗分類が参照する。

## 正準シェルパターン

```bash
OUT=".ai-out/agent-runs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
PROMPT="$(cat "$OUT/prompt.txt")"   # 事前に固定したプロンプト本文

run_agent() {           # $1=id  $2=timeout秒  $3...=invocation（$PROMPT 展開済み）
  local id="$1" tmo="$2"; shift 2
  timeout "$tmo" "$@" >"$OUT/$id.out" 2>&1
  echo $? >"$OUT/$id.exit"
}

# レジストリの各 enabled エージェントについて起動（invocation は context/ai-agents.md から）
run_agent claude 600 claude -p "$PROMPT" --output-format text &
run_agent codex  600 codex exec "$PROMPT" &
run_agent cursor 600 agent --print --model composer-2.5 --output-format text "$PROMPT" &

wait
ls "$OUT"   # <id>.out / <id>.exit が揃う
```

- 上記の各 `run_agent` 行は **レジストリの invocation をそのまま展開** する。CLI 名や flag を此処に固定しない。
- `timeout` の終了コードは 124 (タイムアウト)。失敗分類で利用する。

## harness background を使う場合

- Claude Code の Bash を `run_in_background: true` で 1 エージェント = 1 タスクとして起動してもよい。完了時に再呼び出しされるため、polling は不要。
- ただし失敗分類とリトライを 1 箇所に集約したい場合は、上記の自己完結シェル (1 回の Bash 呼び出しで `wait` まで) の方が決定的で扱いやすい。
- どちらでも per-agent の `<id>.out` / `<id>.exit` を残す契約は守る。

## リトライ

- 失敗分類後に再試行するエージェントだけを、同じ `run_agent` で再度起動する (短いバックオフ `sleep` を挟む)。リトライは `failure-handling.md` の規則で **1 回まで**。
