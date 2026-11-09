# ADR-0010: playbook の手順は番号付きの文のままにし、戻るループのある手順にだけ判定、次の手順、周回の上限を書く

## Status

承認

## Context

playbook の手順は、番号付きの文で書いている。エージェントが手順を todolist に写し、行わない手順にも `skip: <理由>` を付けて残す。

- ADR-0009: [パッケージごとの索引のスキルが playbook の索引を持ち、playbook と principle と場面で読む規則はファイルとして置く](0009-entry-skills-with-playbook-files.md)

手順の中には、前の手順に戻るループがある。レビューと修正（feature、bug-fix）、CI と指摘への対応（pr-follow-up）、配ると確認（coordinate-workers）、検証と撮り直し（verification）。今の文は、戻る先は書くが、どの判定で戻り、何周で止めるかを書いていない。周回が止まらず、同じ修正を繰り返すことがある。

takt は、workflow の YAML で、step ごとに担う役と権限、判定の条件と次の step、周回の上限を宣言する。遷移の強制、どの条件にも当たらないときの停止、周回の数え上げは、実行エンジンが行う。

- 出典: [nrslib/takt](https://github.com/nrslib/takt)

Design Doc の Non-Goals は、作業を次へ進める実行エンジンを持たないと決めている。

Agent Skills の best practices は、失敗しやすい手順は自由度を低く厳密に書き、文脈に依存する作業は方針だけを書くよう勧めている。

- 出典: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

## Decision

- playbook の手順は、番号付きの文のままにする。
- 前の手順に戻るループがある手順にだけ、次の 3 つを書く。
  - 判定のラベル。例: 合格、要修正、尋ねる。
  - ラベルごとの次の手順の番号。
  - 周回の上限と、上限に当たったときの扱い。扱いは、ADR-0006 の 2 段目として論点を尋ねるか、止まるかにする。
    - ADR-0006: [作業の中の判断を、推奨で決めて進める、尋ねて進める、止まるの 3 段に分け、論点の尋ね方を 1 つにする](0006-three-tiers-of-decisions.md)
- 対象は、feature、bug-fix、pr-follow-up、coordinate-workers、verification のループにする。ほかの playbook にループを足すときも、同じ形で書く。
- 遷移を強制する仕組み（YAML の定義、遷移を進めるプログラム）は持たない。Non-Goals を保つ。

書き方の例は次のとおり。

```text
7. 差分をレビューする。判定が「合格」なら手順 8 へ、「要修正」なら直して手順 7 に戻る。3 周しても「要修正」が残れば、残った指摘を論点として尋ねる。
```

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** 番号付きの文のまま、ループのある手順にだけ判定、次、上限を書く | 変更が小さい。周回が止まらない誤りを抑えられる | 遷移を強制できない。守るかはエージェントに任される |
| すべての手順を、役、入力、終える条件、判定と次の表にそろえる | 手順の形を機械的に点検できる | playbook が長くなり、ループの無い手順まで表になる |
| YAML で手順を定義し、形を点検するスクリプトを持つ | 形の誤りを CI で止められる | 実行エンジンが無いので、YAML の遷移も守らせられない。Markdown と YAML の 2 か所に手順が分かれる |

## Consequences

### Positive

- ループのある手順で、戻る判定と止まる周回が決まる。
- 上限に当たった論点が、判断の 3 段の形で利用者に届く。

### Negative

- 上限の数は playbook ごとに決める必要がある。
- 遷移は今のとおりエージェントの判断に頼り、守られたかは機械で確認できない。
