# ADR-0003: release-please でタグを付け、packages/ を変えたコミットだけでバージョンを上げる

## Status

承認

## Context

利用者は、`apm.yml` にタグを書いて、このパッケージを入れる。タグは利用者との契約で、利用者のロックファイルはタグとコミットを記録する。

前提にする agent-harness は、release-please でタグとリリースを作っている。同じ人が両方を保守するので、手順をそろえたい。

- agent-harness の ADR-0007: [main と作業用のブランチだけで運用し、release-please でタグを付ける](https://github.com/Fukuemon/agent-harness/blob/v0.2.1/adr/0007-branch-and-release.md)
- agent-harness の ADR-0019: [packages/ を変えたコミットだけでバージョンを上げ、切り戻しは新しいバージョンで行う](https://github.com/Fukuemon/agent-harness/blob/v0.2.1/adr/0019-release-scope-and-rollback.md)

v0.1.0 のタグは、release-please を入れる前に、手で付けた。

## Decision

agent-harness と同じ形にし、次の 4 点だけを変える。

- release-please の対象の path を `packages` にし、バージョンを書き換えるのは `packages/playbooks/.claude-plugin/plugin.json` と、README の導入の例の行にする。README の行は、`x-release-please-version` の目印で書き換える。
- ルートの `apm.yml` は agent-harness だけを指し、このリポジトリのパッケージを含まない。そのため、リリース用の pull request で `apm.lock.yaml` を作り直す手順は持たない。
- manifest の始まりを 0.1.0 にし、`last-release-sha` を v0.1.0 のコミットにする。v0.1.0 の後のコミットから、変更履歴を作る。
- 破壊的な変更は、スキルと playbook の改名と削除、前提にする agent-harness のバージョンを上げることとする。

リリース用の pull request は、GitHub App のトークンで作る。`GITHUB_TOKEN` で作った pull request では、CI が動かないためである。App の client ID と秘密鍵は、リポジトリの secret（`RELEASE_APP_CLIENT_ID`、`RELEASE_APP_PRIVATE_KEY`）に置く。

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** agent-harness と同じ release-please と GitHub App | 2 つのリポジトリで手順がそろう。リリース用の pull request でも CI が動く | App の導入と secret の登録が要る |
| release-please と `GITHUB_TOKEN` | secret が要らない | リリース用の pull request で CI が動かず、取り込む前に手で動かす必要がある |
| 手でタグを付ける | 仕組みが要らない | 変更履歴とバージョンの決め方が、人の判断に頼る |

## Consequences

### Positive

- コミットメッセージから、バージョンと変更履歴が決まる。
- 利用者は、README の導入の例をそのまま写せば、最新のタグを入れられる。

### Negative

- コミットの type を誤ると、バージョンの上げ方を誤る。
- App の導入と secret の登録が終わるまで、リリースの仕組みは動かない。
