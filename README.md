# agent-playbooks

コーディングエージェントが作業をどの順に進めるかを、playbook として持つパッケージ群。  
依頼を受けたエージェントが索引のスキル `run-playbook` か `run-session` を読み、依頼に合う playbook を選び、その手順で進める。

[agent-harness](https://github.com/Fukuemon/agent-harness) の core と docs を前提にする。context、文書の型、コミットと issue と pull request の規約は agent-harness が持ち、このパッケージは作業の進め方だけを持つ。  
agent-harness の製品のパッケージ（verification、e2e、screens、design-system、docs-site）は任意である。入れたパッケージのスキルは、playbook の段から呼ばれる。入れていないパッケージの段は飛ばされる。

## Packages

| パッケージ | 役割 |
| --- | --- |
| playbooks | 工程ごとの playbook を選ぶスキル `run-playbook` と、playbook、principle、共通の規則の本体、手順を組むスキル `design-playbook` |
| sessions | 1 回の会話を超える作業の playbook を選ぶスキル `run-session` と、playbook の本体。playbooks の共通の規則を使う |
| review | 観点ごとのレビューのスキル `review-by-viewpoints` と、レビューの subagent。ほかのパッケージに依存しない |

playbooks の playbook は、sessions と review が入っていなければ、それを使う段を飛ばす。

### playbook

| 名前 | パッケージ | 当てはまる依頼 |
| --- | --- | --- |
| requirements | playbooks | 実現したいことを整理し、種別を選んで issue にし、タスクに分ける |
| feature | playbooks | 振る舞いを足すか変える |
| prototype | playbooks | 使い捨ての実装で、設計の判断を決める |
| bug-fix | playbooks | 報告された不具合を再現し、原因を突き止めて直す |
| refactoring | playbooks | 振る舞いを変えずに、構造を変える |
| small-change | playbooks | 設計の判断が要らない小さな変更 |
| investigation | playbooks | コードを変えずに問いに答える |
| opening-a-pr | playbooks | 変更を pull request にする |
| pr-follow-up | playbooks | pull request のレビューの指摘と CI の失敗に対応する |
| verification-setup | playbooks | アプリを利用者と同じ方法で動かして確認する手段を作り、保つ |
| verification | playbooks | 要求の受け入れの条件を、子の実装のマージの後に確認し、エビデンスを検証の pull request に載せる |
| design-system | playbooks | デザインシステムを導入するか、トークン、コンポーネント、原則を足すか変える |
| screen-spec | playbooks | 画面仕様書を実装より先に書くか、実装と読み合わせる |
| reflect | playbooks | 終えた作業から学びを取り出し、context か配布元へ書き戻す |
| correct | playbooks | 繰り返す誤りを、型、チェック、テストのような仕組みで止める |
| autonomous-run | sessions | 決めた終了の条件まで、止まらずに進める |
| pause-safely | sessions | 作業を、続きから再開できる形で止める |
| session-pickup | sessions | 前の会話や別のエージェントの作業を、続きから再開する |
| delegate-work | sessions | 作業を別のセッションに渡す。引き継ぎのメモか、ワーカーへの指示を作る |
| coordinate-workers | sessions | 依存を並べた複数の作業をワーカーに配り、マージと片付けまで繰り返す |

## Installation

agent-harness を導入したリポジトリの `apm.yml` に、使うパッケージの行を足す。タグは、agent-harness もこのリポジトリも、パッケージごとの `<名前>-v<バージョン>` の形で書く。

```yaml
dependencies:
  apm:
    - Fukuemon/agent-harness/packages/core#core-v0.2.12
    - Fukuemon/agent-harness/packages/docs#docs-v0.2.14
    - Fukuemon/agent-playbooks/packages/playbooks#playbooks-v0.3.0 # x-release-please-version
    - Fukuemon/agent-playbooks/packages/sessions#sessions-v0.1.0
    - Fukuemon/agent-playbooks/packages/review#review-v0.1.0
```

製品のパッケージは、プロダクトに要るものだけを足す。

```yaml
    - Fukuemon/agent-harness/packages/verification#verification-v0.3.1
    - Fukuemon/agent-harness/packages/e2e#e2e-v0.2.1
    - Fukuemon/agent-harness/packages/screens#screens-v0.1.2
    - Fukuemon/agent-harness/packages/design-system#design-system-v0.3.0
    - Fukuemon/agent-harness/packages/docs-site#docs-site-v0.1.3
```

sessions は playbooks を前提にする。review は単独で入れてよい。  
タグとバージョンごとの変更は [Releases](https://github.com/Fukuemon/agent-playbooks/releases) にある。`v0.2.3` までのタグは、3 つに分ける前の 1 つのパッケージ playbooks のものである。

```sh
apm install
```

## Usage

コーディングエージェントで、依頼を添えて `/run-playbook` を呼ぶ。1 回の会話を超える作業（終わるまで続ける、止めて再開する、別のセッションに渡す、ワーカーに配る）は `/run-session` を呼ぶ。依頼の内容から、スキルが自動で読み込まれることもある。

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
条件は、スキル run-playbook の `rules/pre-granted-permission.md` にある。

作業の中の判断は、止まらずに次のように扱う。

- 見た目、文言、内部の命名のような、後から戻せる小さな判断は、推奨の案で決めて進め、pull request や報告でまとめて伝える。
- issue と設計の文書に無い動き、業務の語、権限、データの扱い、範囲、優先順位は、選択肢と推奨を添えて尋ね、答えを待つ間はほかの作業を進める。

## Documentation

- [Design Doc](design/DesignDoc.md): パッケージの構成と、agent-harness との分担。

## Contributing

開発の準備と、変更をマージするまでの手順は [CONTRIBUTING.md](CONTRIBUTING.md) にある。
