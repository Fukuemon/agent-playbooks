# agent-playbooks

コーディングエージェントが作業をどの順に進めるかを、playbook として持つパッケージ。  
依頼を受けたエージェントがスキル `run-playbook` を読み、依頼に合う playbook を選び、その手順で進める。

[agent-harness](https://github.com/Fukuemon/agent-harness) の core と docs を前提にする。context、文書の型、コミットと issue と pull request の規約は agent-harness が持ち、このパッケージは作業の進め方だけを持つ。

## Packages

| パッケージ | 役割 |
| --- | --- |
| playbooks | playbook を選ぶスキル `run-playbook` と、playbook と principle の本体、手順を組むスキル `design-playbook`、レビューのスキル `review-changes` とレビューの subagent |

### playbook

| 名前 | 当てはまる依頼 |
| --- | --- |
| requirements | 実現したいことを整理して issue にする |
| feature | 振る舞いを足すか変える |
| prototype | 使い捨ての実装で、設計の判断を決める |
| bug-fix | 報告された不具合を再現し、原因を突き止めて直す |
| refactoring | 振る舞いを変えずに、構造を変える |
| small-change | 設計の判断が要らない小さな変更 |
| investigation | コードを変えずに問いに答える |
| opening-a-pr | 変更を pull request にする |
| pr-follow-up | pull request のレビューの指摘と CI の失敗に対応する |
| verification-setup | アプリを利用者と同じ方法で動かして確認する手段を作り、保つ |
| reflect | 終えた作業から学びを取り出し、context か配布元へ書き戻す |
| correct | 繰り返す誤りを、型、チェック、テストのような仕組みで止める |
| autonomous-run | 決めた終了の条件まで、止まらずに進める |
| pause-safely | 作業を、続きから再開できる形で止める |
| session-pickup | 前の会話や別のエージェントの作業を、続きから再開する |
| delegate-work | 作業を別のセッションに渡す。引き継ぎのメモか、ワーカーへの指示を作る |
| coordinate-workers | 依存を並べた複数の作業をワーカーに配り、マージと片付けまで繰り返す |

## Installation

agent-harness を導入したリポジトリの `apm.yml` に、1 行を足す。

```yaml
dependencies:
  apm:
    - Fukuemon/agent-harness/packages/core#v0.2.1
    - Fukuemon/agent-harness/packages/docs#v0.2.1
    - Fukuemon/agent-playbooks/packages/playbooks#v0.2.2 # x-release-please-version
```

タグとバージョンごとの変更は [Releases](https://github.com/Fukuemon/agent-playbooks/releases) にある。

```sh
apm install
```

## Usage

コーディングエージェントで、依頼を添えて `/run-playbook` を呼ぶ。依頼の内容から、スキルが自動で読み込まれることもある。

```text
/run-playbook ログインの画面で、パスワードを間違えたときのメッセージが出ない。直して
```

スキル run-playbook が playbook を選び、その手順を todolist に写して進める。  
止まって指示を待つのは、次の操作の前。

- push、pull request のマージ、デプロイ
  - push は、作業用のブランチへの push も含む。
- データの削除と、取り消せない変更
- 外部のサービスへの送信
  - issue と pull request の作成と書き換えも含む。

利用者が事前に与えた権限（引き継ぎのメモの委任のセクションか、利用者の個人の常設の指示）がある範囲では止まらない。  
条件は、スキル run-playbook の「事前の権限」にある。

## Documentation

- [Design Doc](design/DesignDoc.md): パッケージの構成と、agent-harness との分担。

## Contributing

開発の準備と、変更をマージするまでの手順は [CONTRIBUTING.md](CONTRIBUTING.md) にある。
