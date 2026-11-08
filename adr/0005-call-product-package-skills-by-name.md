# ADR-0005: playbook から agent-harness の製品のパッケージのスキルを名前で呼び、入っていないパッケージの段は飛ばす

## Status

承認

## Context

playbook の手順は、コミット、issue、pull request、Design Doc、context を書く場面を含む。これらの書き方は、agent-harness の core と docs のスキルが持つ。

agent-harness のスキル write-skill は、パッケージとして配るスキルに、ほかのパッケージのスキルを名前で呼ばないことを求めている。そのパッケージが入っていない利用者には、存在しないスキルになるためである。

一方、このパッケージは agent-harness の上で動く具体のワークフローのハーネスで、agent-harness のパッケージを前提にする。

agent-harness は、core と docs のほかに、関心ごとの製品のパッケージを配るようになった。利用者は、要るものだけを選んで入れる。

| パッケージ | 持つスキル |
| --- | --- |
| verification | design-test-cases、write-verification-spec、run-verification-scenarios、capture-browser-evidence、capture-pull-request |
| e2e | setup-e2e、write-e2e-test |
| screens | write-screen-spec |
| design-system | setup-design-system、write-design-system |
| docs-site | publish-docs-site |

検証の設計、エビデンスの撮影と pull request への添付、画面仕様書、デザインシステムの手順は、これらのパッケージのスキルだけが持つ。ADR-0001 のままでは、playbook の段からこれらを呼べない。

利用者の個人の構成のスキルは、製品のパッケージと分けて扱われ、ほかの利用者には届かない。

agent-harness のタグは、リポジトリ全体の `v<バージョン>` から、パッケージごとの `<名前>-v<バージョン>` に移った。

## Decision

- このパッケージは、agent-harness の core と docs が入っていることを前提にする。README の導入の手順に、3 つを並べて書く。
- playbook とスキルは、core と docs のスキル（write-commit、write-issue-pr、write-design-docs、write-context、write-prose）を名前で呼ぶ。
- playbook とスキルは、製品のパッケージ（verification、e2e、screens、design-system、docs-site）のスキルも名前で呼ぶ。製品のパッケージは任意とし、README の導入の手順に、任意のものとして並べる。
- 製品のパッケージのスキルを呼ぶ段は、そのスキルが配置されていなければ、todolist に `skip: <パッケージ名> のパッケージが無い` と残して飛ばす。段を飛ばしても、playbook の残りの手順は進める。
  - スキルの代わりの手順を playbook に写さない。同じ規則が 2 か所に分かれ、片方だけが更新されて食い違うためである。
  - 飛ばした段で失われる確認（エビデンスの添付など）は、返答と pull request の「確認したこと」に「未実施」と理由を書く。
- 利用者の個人の構成のスキルは、名前で呼ばない。製品に要る規則は、agent-harness の core か製品のパッケージに移してから呼ぶ。別のセッションの起動や worktree の作り方のような、ツールに依る手順は、今のとおり一般の語で書き、具体は利用者の context か個人の構成に任せる。
- README と Design Doc の導入の例には、パッケージごとのタグを書く。前提にするタグを上げることは、今のとおり破壊的な変更として扱う。

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** core と docs を前提にし、製品のパッケージも名前で呼び、入っていなければ段を飛ばす | 書き方と手順の規則を 1 か所に保てる。どのスキルを読めばよいかがエージェントに伝わる。要らないパッケージを入れずに済む | 入っていないパッケージの段は確認が抜ける。スキルの名前が変わると playbook を直す必要がある |
| core と docs だけを名前で呼び、製品のパッケージは「検証のスキルがあれば」のような一般の語で書く | 名前に依存しない | どのスキルを読めばよいかがエージェントに伝わらず、手順が読まれない |
| パッケージごとに、agent-playbooks の側に薄い playbook を分けて置く | 入っていないパッケージの playbook を選ばずに済む | 同じ作業の手順が、パッケージの有無で複数の playbook に分かれる。索引と評価が増える |
| 書き方の規則を playbook に写す | このパッケージだけで動く | 同じ規則が 2 か所に分かれ、片方だけが更新されて食い違う |

## Consequences

### Positive

- コミットや文書の書き方、検証とエビデンスの手順が変わっても、このパッケージを直さなくてよい。
- 利用者は、画面を持たないプロダクトでは verification や screens を入れずに使える。

### Negative

- core、docs、製品のパッケージのスキルの名前が変わると、playbook を直す必要がある。
- core と docs を入れずにこのパッケージだけを入れた利用者では、手順の一部が動かない。
- 製品のパッケージを入れていない利用者では、その段の確認が抜ける。抜けたことは、返答と pull request にしか残らない。
