# ADR-0011: release-please でパッケージごとにタグを付け、変えたパッケージのバージョンだけを上げる

## Status

承認

## Context

利用者は、`apm.yml` にタグを書いて、このパッケージを入れる。タグは利用者との契約で、利用者のロックファイルはタグとコミットを記録する。

前提にする agent-harness は、release-please でタグとリリースを作っている。同じ人が両方を保守するので、手順をそろえたい。agent-harness は、`<名前>-v<バージョン>` の形で、パッケージごとにタグを付けている。

v0.1.0 のタグは、release-please を入れる前に、手で付けた。v0.1.0 から v0.2.3 までは、リポジトリ全体で 1 つのバージョンにし、`v<バージョン>` のタグを付けた。

パッケージを `playbooks`、`sessions`、`review` の 3 つに分ける。変わる理由が違うので、変えたパッケージのバージョンだけを上げたい。

- ADR-0008: [パッケージを、工程の playbooks、長い作業と委譲の sessions、レビューの review の 3 つに分ける](0008-split-into-playbooks-sessions-review.md)

## Decision

### release-please の設定

- release-please の `packages` を、`packages/<名前>` のパッケージごとに分ける。各パッケージに `component` としてディレクトリの名前を付け、`include-component-in-tag` を `true` にする。タグは `playbooks-v0.3.0` のような `<名前>-v<バージョン>` の形になる。
- パッケージごとの `extra-files` で、そのパッケージの `.claude-plugin/plugin.json` の `$.version` を書き換える。
- README の導入の例の行は、`playbooks` の `extra-files` だけで、`x-release-please-version` の目印で書き換える。`generic` の updater は、目印のある行をすべて同じバージョンで書き換えるので、目印は `playbooks` の行にだけ置く。`sessions` と `review` の行は、リリース用の pull request をマージする前に、手で直す。
- 変更履歴は、パッケージごとに `packages/<名前>/CHANGELOG.md` に置く。ルートの `CHANGELOG.md` は `v0.2.3` までの記録として残し、更新しない。
- リリース用の pull request は、`separate-pull-requests` を `false` のままにして 1 つにまとめる。
- ルートの `apm.yml` は agent-harness だけを指し、このリポジトリのパッケージを含まない。そのため、リリース用の pull request で `apm.lock.yaml` を作り直す手順は持たない。

### 番号と移り方

- `playbooks` は今の番号の続きから始める。manifest に `packages/playbooks` を `0.2.3` で書く。
- `sessions` と `review` は、`0.1.0` から始める。
- `bootstrap-sha` を、v0.2.3 のリリースのコミットにする。`playbooks-v0.2.3` のタグは無いので、release-please は `bootstrap-sha` の後のコミットから、各パッケージの最初の変更履歴を作る。`bootstrap-sha` は、release-please が作った pull request を一度マージすると使われなくなり、以後は各パッケージの前のリリースから数える。
  - 出典: [release-please の manifest-releaser の文書](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)
- 既存の `v0.1.0` から `v0.2.3` のタグとリリースは、消さずに残し、付け替えない。

### 破壊的な変更とトークン

- 破壊的な変更は、スキルと playbook の改名と削除、playbook のパッケージの間の移動、前提にする agent-harness のバージョンを上げることとする。
- リリース用の pull request は、GitHub App のトークンで作る。`GITHUB_TOKEN` で作った pull request では、CI が動かないためである。App の client ID と秘密鍵は、リポジトリの secret（`RELEASE_APP_CLIENT_ID`、`RELEASE_APP_PRIVATE_KEY`）に置く。

## Considered Options

### バージョンの単位

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** パッケージごとのタグ | 変えたパッケージのバージョンだけが上がる。agent-harness とタグの形がそろう | release-please の設定と README の行が増える。README の `sessions` と `review` の行を手で直す |
| リポジトリ全体で 1 つのバージョン | 設定と README の書き換えが今のまま | 1 つのパッケージを変えても、ほかのパッケージのバージョンも上がる |

### リリースの仕組み

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** agent-harness と同じ release-please と GitHub App | 2 つのリポジトリで手順がそろう。リリース用の pull request でも CI が動く | App の導入と secret の登録が要る |
| release-please と `GITHUB_TOKEN` | secret が要らない | リリース用の pull request で CI が動かず、マージする前に手で動かす必要がある |
| 手でタグを付ける | 仕組みが要らない | 変更履歴とバージョンの決め方が、人の判断に頼る |

## Consequences

### Positive

- コミットメッセージから、パッケージごとのバージョンと変更履歴が決まる。
- 利用者は、使うパッケージのタグだけを上げればよい。

### Negative

- コミットの type を誤ると、バージョンの上げ方を誤る。
- 利用者は、`v0.2.3` までのタグから、パッケージごとのタグに書き換える必要がある。
- README の `sessions` と `review` の導入の行は、リリースのたびに手で直す。
