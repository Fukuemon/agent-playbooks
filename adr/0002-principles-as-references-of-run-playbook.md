# ADR-0002: playbook と principle を 1 つのスキル run-playbook の下に置く

## Status

承認

## Context

playbook は 9 本、principle は 4 つある。どちらも、依頼に合うものだけを読ませたい。

- スキルは、使われなくても説明の分だけ毎回のコンテキストを使う。agent-harness のスキル write-skill は、既にあるスキルに足せる内容なら、スキルを増やさないと決めている。
- スキルの作り方の公式文書は、SKILL.md を目次にして、領域ごとのファイルを要るときだけ読ませる型を挙げている。参照は SKILL.md から 1 段に保つよう求めている。参照されたファイルからさらに別のファイルを参照すると、途中までしか読まれないことがあるためである。
  - 出典: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- principle は、モデルが会話から自分で選ぶものではなく、playbook の手順の中で読むものである。モデルによる自動の読み込みを止める指定は、Claude Code にはあるが、Codex CLI が守るかは確かめていない。
- write-skill は、配るスキルの名前を `<動詞>-<対象>` にすると決めている。`playbook` は動詞がなく、一般的な語で、ほかのパッケージのスキルと名前が重なりやすい。

## Decision

- playbook と principle を選ぶスキルの名前を `run-playbook` にする。
- playbook を `run-playbook/playbooks/`、principle を `run-playbook/principles/` に置く。どちらも frontmatter を持たない Markdown で、単独では読み込まれない。
- `run-playbook` の SKILL.md が、playbook と principle の両方の索引を持つ。playbook の手順が別の playbook や principle の名前を挙げたときも、この索引から開かせる。

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** 1 つのスキルの下に、playbook と principle を置く | 常に使うコンテキストが、スキル 1 つの説明だけになる。参照が SKILL.md から 1 段に収まる | 利用者が principle を名前で呼んで、スキルとして読み込ませることはできない |
| playbook ごとにスキルにする | 依頼から、モデルが直接 playbook を選べる | 説明が 9 つ常駐する。共通の規則を、どのスキルに置くかが決まらない |
| principle を、自動の読み込みを止めたスキルにする | 利用者が principle を名前で呼べる | 説明が 4 つ増える。自動の読み込みを止める指定を守らないホストでは、選ばれる候補に入る |

## Consequences

### Positive

- スキルの説明が増えず、ほかのパッケージのスキルと名前が重なりにくい。
- principle の扱いが、ホストの違いに左右されない。

### Negative

- スキル `run-playbook` の説明に、すべての playbook の依頼の種類を書く必要がある。説明が長くなる。
- playbook を足すたびに、索引と評価の両方を直す必要がある。
