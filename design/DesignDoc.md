---
type: design-doc
title: agent-playbooks Design Doc
description: コーディングエージェントの作業の進め方を playbook として配るパッケージの全体像。構成要素の責務と、agent-harness との分担
status: draft
---

# agent-playbooks Design Doc

## Overview

agent-playbooks は、コーディングエージェントが作業をどの順に進めるかを、playbook として配るパッケージである。  
agent-harness が定める開発プロセスの標準の上で動く、具体のワークフローのハーネスに当たる。

- agent-harness の ADR-0008: [開発プロセスの標準はこのリポジトリに置き、具体のワークフローのハーネスは別のリポジトリに置く](https://github.com/Fukuemon/agent-harness/blob/v0.2.1/adr/0008-workflow-harness.md)

利用者は、agent-harness の core と docs を入れたリポジトリに、このパッケージを足して使う。  
依頼を受けたエージェントがスキル run-playbook を読み、依頼に合う playbook を選び、その手順に沿って作業する。

構成は pstack に倣う。

- [cursor/plugins の pstack](https://github.com/cursor/plugins/tree/main/pstack)

## Goals and Non-Goals

### Goals

- 依頼の種類ごとに、作業の手順を playbook として持つ。手順は番号付きで、各手順から skill と principle を名前で呼ぶ。
- スキル run-playbook が playbook の索引を持ち、依頼から playbook を選ぶ。利用者は playbook の名前を覚えなくてよい。
- 合う playbook がない作業では、その場で手順を組む。
- 手順の途中の判断の基準を、principle として少数持つ。
- 作業の進み具合を、agent-harness の `process.yml` に記録する。

### Non-Goals

- 作業を次へ進める実行エンジン。手順はエージェントが todolist に写して進める。
- context、文書の型、commit と issue と PR の規約。agent-harness の core と docs が持つ。
- 利用者のリポジトリだけの取り決め。利用者の context に置く。

## Assumptions and Constraints

- 利用者は、agent-harness v0.2.1 以上の core と docs を入れている。playbook は、core と docs の skill を名前で呼ぶ。
- 配布は apm で行い、Claude Code と Codex CLI に配置する。形は Claude Code の形式のプラグインにする。
- agent-harness の process のパッケージ（`process.yml` の schema とチェック）はまだない。playbook は、agent-harness の開発プロセスの Design Doc が定める形で `process.yml` を書く。schema のチェックは、process のパッケージができたら使う。

## Architecture

次の図は、利用者のリポジトリで、エージェントが playbook を選んで作業を進めるときの要素の関係を示す。

```mermaid
flowchart TB
    user["利用者の依頼"] --> entry["スキル run-playbook<br>playbook と principle の索引<br>共通の規則"]
    entry -- "合う playbook を開く" --> pb["playbook<br>番号付きの手順"]
    entry -- "合うものがない" --> design["design-playbook<br>その場で手順を組む"]
    entry -- "当てはまる principle を開く" --> pr["principle<br>判断の基準"]
    pb -- "名前で呼ぶ" --> ah["agent-harness の skill<br>write-context / write-design-docs<br>write-commit / write-issue-pr"]
    pb -- "レビューを頼む" --> rv["review-changes と<br>レビューの subagent"]
    pb -- "選択と進み具合を書く" --> proc["specs/&lt;issue&gt;/process.yml"]
```

## Components

### スキル run-playbook

- playbook の索引を持つ。項目ごとに、名前と、どんな依頼に当てはまるかを 1 行で書く。
- すべての playbook に共通する規則を持つ。todolist の作り方、止まって尋ねる場面、返答の形。
- principle の索引を持つ。当てはまる principle だけを全文読ませる。
- playbook と principle の本文は持たない。`playbooks/<名前>.md` と `principles/<名前>.md` に置き、選んだものだけを開く。
- playbook の手順が別の playbook や principle の名前を挙げたときも、この索引から開かせる。参照を SKILL.md から 1 段に保つためである。

### playbook

frontmatter を持たない Markdown で、スキル run-playbook の `playbooks/` に置く。単独では読み込まれない。  
中身は次の 4 つ。

- 担当の範囲。この playbook が何に責任を持ち、隣の playbook と何が違うか。
- 番号付きの手順。各手順から skill と principle を名前で呼ぶ。
- 止まる条件。人の判断を待つ場面。
- 返答に書くこと。

playbook は次のとおり。

| playbook | 当てはまる依頼 | 主に行う開発プロセス |
| --- | --- | --- |
| requirements | 実現したいことを整理して issue にする | requirements |
| feature | 振る舞いを足すか変える | requirements から integration |
| prototype | 使い捨ての実装で、設計の判断や、実行すれば分かる問いに答える | design |
| bug-fix | 報告された不具合を再現し、原因を突き止めて直す | implementation、verification |
| refactoring | 振る舞いを変えずに、構造を変える | implementation、verification |
| small-change | 設計の判断が要らない小さな変更 | implementation、integration |
| investigation | コードを変えずに問いに答える | なし |
| opening-a-pr | 変更を pull request にする。ほかの playbook の最後に呼ぶ | integration |
| pr-follow-up | pull request のレビューの指摘と CI の失敗に対応する | integration |
| verification-setup | アプリを利用者と同じ方法で動かして確かめる手段を作り、保つ | verification-design |
| reflect | 終えた作業から学びを取り出し、context か配布元へ書き戻す | なし |
| correct | 繰り返す誤りを、仕組みで起こせなくする | implementation |
| autonomous-run | 決めた終了の条件まで、止まらずに進める | 組んだ手順による |
| pause-safely | 作業を、続きから再開できる形で止める | なし |
| session-pickup | 前の作業を、続きから再開する | 引き継いだ作業による |

### design-playbook

合う playbook がない作業、範囲が大きい作業、利用者が離れている間に進める作業で使う。  
終了の条件、範囲、確かめ方を先に決め、作業を単独で取り込める単位に分け、その場の手順を組む。組んだ手順は保存しない。

### principle

手順の途中の判断の基準を 1 つずつ書いた Markdown で、スキル run-playbook の `principles/` に置く。skill にはせず、run-playbook の索引から読まれる。  
最初のバージョンは次の 4 つにする。

- prove-it-works: 本物で動かして確かめてから、終わったと言う。
- fix-root-causes: 症状を隠さず、再現してから原因を直す。
- smallest-change: 問題を解く最小の変更を選ぶ。
- encode-lessons: 2 回した訂正は、文章ではなくチェックや仕組みに移す。

### review-changes とレビューの subagent

差分か spec を、観点ごとの subagent に読ませ、指摘を重大度の順にまとめる。subagent は読み取りだけを行う。  
観点は、アーキテクチャ、性能、品質、セキュリティ、spec の 5 つである。

## Interfaces

### 導入

利用者は、`apm.yml` に agent-harness の core と docs と並べて、このパッケージを書く。

```yaml
dependencies:
  apm:
    - Fukuemon/agent-harness/packages/core#v0.2.1
    - Fukuemon/agent-harness/packages/docs#v0.2.1
    - Fukuemon/agent-playbooks/packages/playbooks#<ref>
```

### 呼び方

- 利用者は `/run-playbook` に依頼を添えて呼ぶ。スキル run-playbook が playbook を選ぶ。依頼の内容から、スキルが自動で読み込まれることもある。
- 利用者が playbook の名前を添えたときは、その playbook を使う。

### 利用者のリポジトリに置かれるファイル

- `specs/<issue 番号>-<主題>/process.yml`: feature と requirements の playbook が書く。形は agent-harness の開発プロセスの Design Doc に従う。

## Cross-Cutting Concerns

### 進み具合の記録

- 通常の作業では、進み具合をファイルに残さない。エージェントが playbook の手順を todolist に写し、飛ばす手順にも `skip: <理由>` を付けて残す。
- spec を置く作業だけ、`process.yml` に選んだプロセスと進み具合を書く。

### 止まって尋ねる場面

- 元に戻せる作業は、尋ねずに進めて結果を見せる。
- 取り消せない操作（共有のブランチへの push、取り込み、デプロイ、データの削除、外部への送信）の前と、利用者だけが決められる判断では止まる。
- 実行すれば分かる事実は、尋ねずに確かめる。

### 確かめる手段

- 「本物で確かめる」手順は、利用者のリポジトリの `context/testing/verification.md` の手順で動かす。この文書とスクリプトは、利用者のリポジトリだけの知識なので、スキルではなく context と `scripts/verify/` に置く。verification-setup が作り、保つ。

### 判断の記録

- 長い作業と、利用者が離れている間の作業では、分かれ道の判断を `.ai-out/` に 1 行ずつ追記する。形はスキル run-playbook の共通の規則が持つ。

### 学びの書き戻し

- 同じ訂正を 2 回したら、principle の encode-lessons に従い、チェックか仕組みに移す。手順は correct が、作業の後の振り返りは reflect が持つ。
- playbook と skill の誤りは、作業の途中でも、別の pull request で直す。

## Repository Layout

```text
agent-playbooks/
├── .claude-plugin/
│   └── marketplace.json       パッケージの一覧
├── packages/
│   └── playbooks/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   ├── run-playbook/
│       │   │   ├── SKILL.md    playbook と principle の索引、共通の規則
│       │   │   ├── playbooks/  playbook の本体
│       │   │   └── principles/ principle の本体
│       │   ├── design-playbook/
│       │   └── review-changes/
│       └── agents/            レビューの subagent
├── evals/
│   └── run-playbook.json    依頼と、選ばれるべき playbook
├── scripts/
│   └── eval-run-playbook.mjs 評価を実行する
├── design/
│   └── DesignDoc.md
├── adr/
├── context/
├── apm.yml                    このリポジトリが使う agent-harness
└── README.md
```
