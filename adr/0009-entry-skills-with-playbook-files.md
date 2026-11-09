# ADR-0009: パッケージごとの索引のスキルが playbook の索引を持ち、playbook と principle と場面で読む規則はファイルとして置く

## Status

承認

## Context

playbook は 19 本、principle は 5 つになる。どちらも、依頼に合うものだけを読ませたい。playbook は、パッケージ `playbooks` と `sessions` に分かれる。

- ADR-0008: [パッケージを、工程の playbooks、長い作業と委譲の sessions、レビューの review の 3 つに分ける](0008-split-into-playbooks-sessions-review.md)

- スキルは、使われなくても説明の分だけ毎回のコンテキストを使う。agent-harness のスキル write-skill は、既にあるスキルに足せる内容なら、スキルを増やさないと決めている。
- スキルの作り方の公式文書は、SKILL.md を目次にして、領域ごとのファイルを要るときだけ読ませる型を挙げている。参照は SKILL.md から 1 段に保つよう求めている。参照されたファイルからさらに別のファイルを参照すると、途中までしか読まれないことがあるためである。
  - 出典: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- Claude Code では、スキルの一覧の文字数の予算は context window の 1% で、超えると呼ばれた回数の少ないスキルから description が落ちる。自動の読み込みを止めたスキルは、一覧に載らない。
  - 出典: [Claude Code の Skills](https://code.claude.com/docs/en/skills)
- principle は、モデルが会話から自分で選ぶものではなく、playbook の手順の中で読むものである。モデルによる自動の読み込みを止める指定は、Claude Code にはあるが、Codex CLI が守るかは確認していない。
- write-skill は、配るスキルの名前を `<動詞>-<対象>` にすると決めている。`playbook` は動詞がなく、一般的な語で、ほかのパッケージのスキルと名前が重なりやすい。
- write-skill は、SKILL.md を 150 行以内に保つと決めている。run-playbook の SKILL.md は 113 行で、判断の 3 段と新しい playbook を足すと 150 行を超える見込みである。
- pstack は、playbook を索引のスキルの `playbooks/` にファイルとして置き、索引のスキルが索引を持つ。単独で使う能力は、別のスキルにしている。
  - 出典: [backnotprop/pstack](https://github.com/backnotprop/pstack)

## Decision

- パッケージ `playbooks` の索引のスキルを `run-playbook`、パッケージ `sessions` の索引のスキルを `run-session` にする。
- playbook を索引のスキルの `playbooks/` に、principle を `run-playbook/principles/` に置く。どちらも frontmatter を持たない Markdown で、単独では読み込まれない。
- 索引のスキルの SKILL.md が、そのパッケージの playbook の索引を持つ。`run-playbook` は principle の索引も持つ。playbook の手順が別の playbook や principle の名前を挙げたときも、その playbook を持つ索引のスキルの索引から開かせる。
- 索引のスキルは、自動で読み込まれる設定のままにする。コンテキストの使用量の知らせを受けたときにも、run-session が開かれるようにするためである。
- 単独で使える能力（design-playbook、review-by-viewpoints）は、別のスキルのままにする。
- run-playbook の索引は、工程ごとのまとまり（要求と設計、実装、確認、pull request、学び）に並べる。
- 共通の規則のうち、場面を選んで読むもの（事前の権限、判断の記録、ワーカーとサブエージェント）は `run-playbook/rules/<名前>.md` に置く。索引に、読む場面を 1 行ずつ書く。SKILL.md には、どの作業にも当たる規則（todolist、作業の前に読むもの、判断の 3 段、返答）を残し、150 行以内に保つ。
- run-session は、共通の規則を写さず、スキル run-playbook の `rules/` を名前で開く。

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** パッケージごとの索引のスキルが索引を持ち、playbook、principle、場面で読む規則はファイル | 一覧の予算を使うスキルが 4 つで済む。参照が SKILL.md から 1 段に収まる。SKILL.md が 150 行以内に収まる | 利用者は playbook を `/` から直接呼べず、索引のスキルに名前を添える。索引の読む場面を読み落とすと、規則を読まずに進む |
| playbook ごとにスキルにする | 依頼から、モデルが直接 playbook を選べる。`/feature` のように呼べる | description が 19 本になり、一覧の予算を取り合う。似た description から選び誤る。共通の規則を、どのスキルに置くかが決まらない |
| 長い作業と委譲の playbook を、自動の読み込みを止めたスキルにする | `/pause-safely` のように利用者が直接呼べる | コンテキストの使用量の知らせを受けたときに、自動で開かれない |
| principle を、自動の読み込みを止めたスキルにする | 利用者が principle を名前で呼べる | 説明が 5 つ増える。自動の読み込みを止める指定を守らないホストでは、選ばれる候補に入る |

## Consequences

### Positive

- スキルの説明が増えず、ほかのパッケージのスキルと名前が重なりにくい。
- principle の扱いが、ホストの違いに左右されない。
- 共通の規則が run-playbook の 1 か所にだけある。

### Negative

- 索引のスキルの説明に、そのパッケージのすべての playbook の依頼の種類を書く必要がある。説明が長くなる。
- playbook を足すたびに、索引と評価の両方を直す必要がある。
- run-session は、run-playbook が入っていないと規則を開けない。
