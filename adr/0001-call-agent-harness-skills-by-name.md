# ADR-0001: playbook から agent-harness の core と docs のスキルを名前で呼ぶ

## Status

承認

## Context

playbook の手順は、コミット、issue、pull request、Design Doc、context を書く場面を含む。これらの書き方は、agent-harness の core と docs のスキルが持つ。

agent-harness のスキル write-skill は、パッケージとして配るスキルに、ほかのパッケージのスキルを名前で呼ばないことを求めている。そのパッケージが入っていない利用者には、存在しないスキルになるためである。

一方、agent-harness の ADR-0008 は、具体のワークフローのハーネスが agent-harness のパッケージに依存すると決めている。

- agent-harness の ADR-0008: [開発プロセスの標準はこのリポジトリに置き、具体のワークフローのハーネスは別のリポジトリに置く](https://github.com/Fukuemon/agent-harness/blob/v0.2.1/adr/0008-workflow-harness.md)

## Decision

- このパッケージは、agent-harness の core と docs が入っていることを前提にする。README の導入の手順に、3 つを並べて書く。
- playbook とスキルは、core と docs のスキル（write-commit、write-issue-pr、write-design-docs、write-context）を名前で呼ぶ。
- core と docs 以外のパッケージのスキルは、名前で呼ばない。

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** core と docs を前提にし、名前で呼ぶ | 書き方の規則を 1 か所に保てる。playbook が短くなる | core と docs が入っていない利用者では、手順の一部が動かない |
| 書き方の規則を playbook に写す | このパッケージだけで動く | 同じ規則が 2 か所に分かれ、片方だけが更新されて食い違う |
| 「コミットの規約に従う」のように一般の語で書く | 名前に依存しない | どのスキルを読めばよいかがエージェントに伝わらず、規約が読まれない |

## Consequences

### Positive

- コミットや文書の書き方が変わっても、このパッケージを直さなくてよい。

### Negative

- core と docs のスキルの名前が変わると、playbook を直す必要がある。
- core と docs を入れずにこのパッケージだけを入れた利用者では、手順の一部が動かない。
