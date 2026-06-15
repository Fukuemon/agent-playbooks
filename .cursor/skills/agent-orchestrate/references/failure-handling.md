# Failure Handling

エージェント実行結果の分類と、リトライ/スキップ方針。方針は「**1 回リトライ後スキップ・部分成功許容**」。

## 分類規則

各エージェントの `<id>.exit` と `<id>.out` を見て分類する。複数条件に一致しうるため、**上から順に最初に一致した status を採る** (評価順: `timeout` → `auth` → `limit` → `error` → `ok`)。例: 出力に `429` と `unauthorized` の両方を含む場合は `auth` を優先する。

| status    | 判定                                                                           |
| --------- | ------------------------------------------------------------------------------ |
| `ok`      | exit=0 かつ出力が空でなく、`limit_patterns` に一致しない                       |
| `limit`   | `limit_patterns` の文字列に一致、または exit が rate/quota を示す (例: 429 系) |
| `auth`    | 出力に認証エラー (`unauthorized` / `not logged in` / `401`)                    |
| `timeout` | exit=124 (`timeout` コマンドによる打ち切り)                                    |
| `error`   | 上記以外の非 0 exit、または exit=0 でも出力が空/壊れている                     |

- `limit_patterns` は `context/ai-agents.md` の各エージェント定義から読む。

## リトライ方針

- **対象**: `limit` と、一過性が疑われる `error` (ネットワーク系)。
- **回数**: 1 回のみ。短いバックオフ (`sleep 5` 程度) を挟んで同一 invocation を再実行する。
- **非対象**: `auth` はリトライしない (設定不備のため即スキップし、ユーザーへ認証を促す)。`timeout` は invocation/モデルの問題が多いので原則リトライせずスキップ (必要時のみユーザー判断)。

## スキップと続行

- リトライ後もダメなエージェントは当該 status のまま **スキップ** し、残りエージェントの結果で続行する。
- 全エージェントが非 `ok` の場合のみ全体を停止する (skill の `停止条件`)。

## status テーブル様式

報告は次の形式で出す:

```text
| agent        | status | retries | output                             |
| ------------ | ------ | ------- | ---------------------------------- |
| <agent_id_1> | ok     | 0       | .ai-out/agent-runs/<ts>/<id_1>.out |
| <agent_id_2> | limit  | 1       | (skipped: usage limit)             |
| <agent_id_3> | ok     | 0       | .ai-out/agent-runs/<ts>/<id_3>.out |
```

- `auth` のときは認証手順 (`auth_note`) を併記する。
- token 浪費を避けるため、`auth` / 設定不備が原因のものは再試行ループに入れない。
