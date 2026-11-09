---
name: run-playbook
description: 依頼に合う playbook を選び、その手順で作業を進める。機能の追加、要求の整理、不具合の修正、小さな変更、構造の整理、設計を決めるための試作、調査、画面仕様書を書く、デザインシステムの導入と整備、要求の受け入れの検証、pull request を開く、pull request の指摘に対応する、検証の手段を作る、作業の振り返り、繰り返す誤りを仕組みで止める、のどれかを始めるとき、または /run-playbook で呼ばれたときに使う。
---

# run-playbook

依頼を受けたら、下の索引から playbook を 1 つ選び、そのファイルを開いて、その手順で進める。  
利用者が playbook の名前を添えたときは、その playbook を使う。どの playbook でも、この本文の「共通の規則」を当てる。

## 選び方

- 索引のどれかに当てはまる作業は、その playbook を使う。
- どれにも当てはまらない作業と、多くの箇所にまたがる作業は、スキル design-playbook で手順を組む。
- 1 回の会話を超える作業（終わるまで続ける作業、作業の中断と再開、別のセッションに渡す作業、複数のワーカーに配る作業）は、スキル run-session の playbook を使う。手順が決まっていない作業は、run-session の autonomous-run の中で design-playbook を使って手順を組む。スキル run-session が無ければ、`skip: sessions のパッケージが無い` とし、この索引の playbook で 1 回の会話の中で進める。
- 1 つの依頼が 2 つの playbook にまたがるときは、先に行う方を選び、終えてから次を選び直す。

## playbook の索引

playbook の手順が別の playbook の名前を挙げたら、この索引からそのファイルを開く。

### 要求と設計

- **requirements:** 実現したいことを整理して、issue にする。まだ作るものが決まっていない依頼。[playbooks/requirements.md](playbooks/requirements.md)
- **prototype:** 作ってみないと決まらない判断を、使い捨ての実装で決める。画面の案、操作、方式、速さを、複数の案を作って比べる。成果物は判断で、出荷するコードではない。[playbooks/prototype.md](playbooks/prototype.md)
- **investigation:** 今あるコードと記録を読んで、問いに答える。どう動くか、なぜこうなっているか、既にある選択肢のどちらがよいか。新しく作って比べる判断は、prototype である。[playbooks/investigation.md](playbooks/investigation.md)
- **screen-spec:** 画面仕様書（画面ごとの文書と操作できるモック）を、実装より先に書くか、既にある実装と読み合わせる。実装はしない。[playbooks/screen-spec.md](playbooks/screen-spec.md)

### 実装

- **feature:** 振る舞いを足すか変える。設計の判断が要る変更。[playbooks/feature.md](playbooks/feature.md)
- **bug-fix:** 報告された不具合を再現し、原因を突き止めて直す。[playbooks/bug-fix.md](playbooks/bug-fix.md)
- **refactoring:** 振る舞いを変えずに、構造を変える。名前の変更、抽出、重複の統合、移動。[playbooks/refactoring.md](playbooks/refactoring.md)
- **small-change:** 設計の判断が要らない変更。誤記の修正、設定の値の変更、依存の更新、文書の直し。[playbooks/small-change.md](playbooks/small-change.md)
- **design-system:** デザインシステムを導入するか、トークン、コンポーネント、原則を足すか変える。画面の実装は feature である。[playbooks/design-system.md](playbooks/design-system.md)

### 確認

- **verification-setup:** アプリを利用者と同じ方法で動かして確認する手段を作るか、アプリの変化に合わせて直す。[playbooks/verification-setup.md](playbooks/verification-setup.md)
- **verification:** 要求の受け入れの条件を、子の実装の pull request がマージされた後に確認する。検証の設計を書き、エビデンスを検証の pull request に載せ、検証の issue と親の要求を閉じる。[playbooks/verification.md](playbooks/verification.md)

### pull request

- **opening-a-pr:** 変更を pull request にする。ほかの playbook の最後に行う。[playbooks/opening-a-pr.md](playbooks/opening-a-pr.md)
- **pr-follow-up:** pull request のレビューの指摘と、CI の失敗に対応する。[playbooks/pr-follow-up.md](playbooks/pr-follow-up.md)

### 学び

- **reflect:** 終えた作業から学びを取り出し、context か配布元へ書き戻す。「振り返って」「学びを残して」。[playbooks/reflect.md](playbooks/reflect.md)
- **correct:** 繰り返す誤りを、型、チェック、テストのような仕組みで起こせなくする。「同じ間違いを止めて」。[playbooks/correct.md](playbooks/correct.md)

## principle の索引

手順の途中で次の場面に当たったら、対応するファイルを全文読んでから判断する。playbook の手順が principle の名前を挙げたときも、ここから開く。  
返答には、読んだ principle と、それで変えた判断を書く。

- **prove-it-works:** 作業を終えたと言う前。[principles/prove-it-works.md](principles/prove-it-works.md)
- **fix-root-causes:** 不具合や失敗の原因を探すとき。症状を消す修正を足したくなったとき。[principles/fix-root-causes.md](principles/fix-root-causes.md)
- **smallest-change:** 変更の大きさを決めるとき。抽象化や層を足したくなったとき。[principles/smallest-change.md](principles/smallest-change.md)
- **encode-lessons:** 同じ訂正や指示を 2 回目に書いたとき。[principles/encode-lessons.md](principles/encode-lessons.md)
- **bound-every-wait:** 自動のレビュー、CI、ほかのセッションの返事のような、外部の待ちを始めるとき。[principles/bound-every-wait.md](principles/bound-every-wait.md)

## 規則の索引

次の場面に当たったら、対応するファイルを全文読んでから進める。

- **事前の権限:** 委任のセクションか利用者の個人の常設の指示がある作業で、3 段目の操作の前に止まるかを決めるとき。推奨で決めてよい判断の範囲を広げるとき。[rules/pre-granted-permission.md](rules/pre-granted-permission.md)
- **判断の記録:** 長い作業、利用者が離れている間の作業、手順を組んだ作業、別のセッションに渡す作業で、分かれ道の判断をしたとき。[rules/decision-log.md](rules/decision-log.md)
- **ワーカーとサブエージェント:** サブエージェントかワーカーを起動するとき。ワーカーから問いを受けたとき。[rules/workers-and-subagents.md](rules/workers-and-subagents.md)

## 共通の規則

### todolist

- playbook を開いたら、その手順をそのまま todolist の先頭に写す。作業に固有の項目は、その後ろに足す。
- 行わない手順も消さず、`skip: <理由>` を付けて残す。

### 作業の前に読むもの

- リポジトリの `AGENTS.md` と `context/index.md` を読み、作業に関係する context を開く。
- 利用者のリポジトリの取り決めと playbook が食い違ったら、リポジトリの取り決めに従い、食い違いを返答に書く。

### 判断の 3 段

作業の中の判断を、次の 3 段に分ける。どの段にも当たらない判断は、2 段目として扱う。

| 段 | 当たる判断 | 扱い |
| --- | --- | --- |
| 1. 推奨で決めて進める | 見た目、文言、内部の命名のような、後から戻せる小さな判断 | 推奨の案で決めて進め、判断の記録に残す。区切り（pull request、報告、親への完了の通知）でまとめて伝える。pull request では「レビューしてほしい点」に書く |
| 2. 尋ねて進める | issue と設計の文書に無い動き、業務の語、権限、データの扱い、範囲、優先順位 | 決めずに、下の「論点の尋ね方」で尋ねる。答えを待つ間は、その論点に依存しない作業を進める。依存する作業しか残らなければ止まる |
| 3. 止まる | 下の操作のうち、事前の権限の範囲に無いもの | 操作の前で止まり、利用者の明示の指示を待つ |

- 3 段目の操作は、次のとおり。
  - push、pull request のマージ、デプロイ。push は、自分の作業用のブランチへの push も、pull request を開く前か後かを問わず含む。
  - データの削除と、取り消せない変更。
  - 外部のサービスへの送信。issue と pull request の作成と書き換えを含む。
- 1 段目の範囲は、委任のセクションでだけ広げられる。条件は規則の索引の「事前の権限」にある。
- 元に戻せる作業は、尋ねずに進めて、結果を見せる。
- 実行すれば分かる事実（動き、出力、性能、見た目）は、判断に含めず、尋ねずに確認する。確認するのに試作が要るなら、prototype を使う。

### 論点の尋ね方

2 段目の論点は、1 つずつ、次の形で尋ねる。

- 選択肢を 2〜4 つ並べる。
- 推奨の案と、その理由を書く。
- 決まらないと進めない作業を書く。決まるまでに進める作業があれば、それも書く。

利用者と対話しているときは会話で尋ねる。ワーカーは、規則の索引の「ワーカーとサブエージェント」のとおり親に尋ねる。どちらの場合も、同じ形の論点を引き継ぎのメモの「返事待ち」に書く。

### 返答

- playbook の「返答に書くこと」を必ず含める。
- 1 段目で推奨の案に決めた判断を、まとめて書く。
- 取り消せない操作の前で止まったときは、次に利用者がする操作を 1 つ書く。

### skill と playbook の誤り

作業の途中で playbook やスキルの誤りに気づいたら、回避して先へ進めない。誤りを返答に書き、別の pull request で直す。
