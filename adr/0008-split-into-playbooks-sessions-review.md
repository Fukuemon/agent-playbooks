# ADR-0008: パッケージを、工程の playbooks、長い作業と委譲の sessions、レビューの review の 3 つに分ける

## Status

承認

## Context

パッケージは `playbooks` の 1 つで、次を持つ。

- スキル run-playbook: 17 の playbook と 5 つの principle の索引と、共通の規則。
- スキル design-playbook: 合う playbook が無い作業の手順を組む。
- スキル review-changes と、5 つのレビューの subagent（architecture、performance、quality、security、spec）。

1 つのパッケージの中身は、変わる理由が 3 つに分かれている。

- 工程の playbook（要求から pull request まで）は、agent-harness のスキルが変わると変わる。製品のパッケージのスキルを呼ぶ段が、これから増える。
  - ADR-0005: [playbook から agent-harness の製品のパッケージのスキルを名前で呼び、入っていないパッケージの段は飛ばす](0005-call-product-package-skills-by-name.md)
- 長い作業と委譲の playbook と引き継ぎのメモは、別のセッションを立ち上げる手段、コンテキストの使用量の知らせ、監視の手段が変わると変わる。対象の playbook は、autonomous-run、pause-safely、session-pickup、delegate-work、coordinate-workers である。
  - ADR-0007: [事前の権限は委任のセクションか利用者の個人の常設の指示に書いたときだけ使い、再開のメモ、判断の記録、動いているものを主題のディレクトリの引き継ぎのメモにまとめる](0007-pre-granted-permission-and-handoff-memo-placement.md)
- レビューは、観点を足すと変わる。playbook を使わない作業でも使える。

1 つのパッケージでは、どれを変えても、ほかの 2 つと同じバージョンが上がる。

レビューのスキルの名前 review-changes は、利用者の個人の構成にある、ホスティングサービスの pull request をレビューするスキルと重なる。パッケージマネージャーは、同じ名前のスキルを後から入れた側で上書きする。

## Decision

| パッケージ | 持つもの |
| --- | --- |
| `playbooks` | 索引のスキル run-playbook。工程の playbook（requirements、feature、bug-fix、refactoring、small-change、prototype、investigation、opening-a-pr、pr-follow-up、verification-setup、verification、design-system、reflect、correct）、principle、共通の規則（事前の権限、判断の 3 段、論点の尋ね方、判断の記録）。スキル design-playbook |
| `sessions` | 索引のスキル run-session。長い作業と委譲の playbook（autonomous-run、pause-safely、session-pickup、delegate-work、coordinate-workers）と、引き継ぎのメモとワーカーへの指示の形 |
| `review` | 観点ごとのレビューのスキル review-by-viewpoints（review-changes を改名したもの）と、5 つのレビューの subagent |

- 依存の向きは、`sessions` から `playbooks` への 1 本だけにする。`sessions` は共通の規則を写さず、スキル run-playbook の規則を名前で開く。同じ規則を 2 つのパッケージに書くと、片方だけが更新されて食い違うためである。
- `review` は、どのパッケージにも依存しない。
- `playbooks` は、`sessions` と `review` に依存しない。手順が `sessions` の playbook か `review` のスキルを挙げる段は、そのパッケージが入っていなければ、ADR-0005 と同じく `skip: <パッケージ名> のパッケージが無い` と残して飛ばす。
  - `review` が無いときは、差分を自分で読み直してからレビューの段を終える。
  - `sessions` が無いときに判断の記録の置き場が要れば、`.ai-out/<主題>/YYYY-MM-DD-<主題>-handoff.md` に「決まったこと」のセクションだけのメモを作る。
- パッケージごとにバージョンを付け、変えたパッケージのバージョンだけを上げる。付け方は ADR-0011 に書く。

## Considered Options

| 選択肢 | 強み | 弱み |
| --- | --- | --- |
| **採用:** `playbooks`、`sessions`、`review` の 3 つ | 変わる理由ごとに分かれ、変えたパッケージのバージョンだけが上がる。レビューと委譲を単独で入れ替えられる | `sessions` が `playbooks` の規則を名前で開く。パッケージをまたぐ段に skip の規則が要る。索引のスキルが 2 つになる |
| `playbooks` と `review` の 2 つ | 共通の規則と委譲の playbook が 1 つのパッケージに残る | 委譲の手段が変わるたびに、工程の playbook のバージョンも上がる |
| 1 つのまま、review-changes を改名するだけ | 配布とバージョンの管理が変わらない | レビューだけを入れられない。変わる理由の違うものが 1 つのバージョンに乗る |

## Consequences

### Positive

- レビューのスキルの名前の重なりが解ける。
- 工程、委譲、レビューのどれかを変えても、ほかのパッケージのバージョンが上がらない。

### Negative

- 利用者は、使うパッケージを 3 つまで `apm.yml` に書く。
- `sessions` だけを入れて `playbooks` を入れない利用者では、規則を開けず、手順の一部が動かない。
- スキル review-changes の改名と、委譲の playbook の `sessions` への移動は、利用者の呼び方が変わる破壊的な変更である。
