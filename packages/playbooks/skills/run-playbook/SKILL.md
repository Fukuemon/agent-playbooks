---
name: run-playbook
description: 依頼に合う playbook を選び、その手順で作業を進める。機能の追加、要求の整理、不具合の修正、小さな変更、構造の整理、設計を決めるための試作、調査、pull request を開く、pull request の指摘に対応する、検証の手段を作る、作業の振り返り、繰り返す誤りを仕組みで止める、終わるまで続ける作業、作業の中断と再開、のどれかを始めるとき、または /run-playbook で呼ばれたときに使う。
---

# run-playbook

依頼を受けたら、下の索引から playbook を 1 つ選び、そのファイルを開いて、その手順で進める。  
利用者が playbook の名前を添えたときは、その playbook を使う。

## 選び方

- 索引のどれかに当てはまる作業は、その playbook を使う。
- どれにも当てはまらない作業と、多くの箇所にまたがる作業は、スキル design-playbook で手順を組む。
- 利用者が離れている間に進める作業は、autonomous-run を使う。手順が決まっていない作業は、autonomous-run の中で design-playbook を使って手順を組む。
- 1 つの依頼が 2 つの playbook にまたがるときは、先に行う方を選び、終えてから次を選び直す。

## playbook の索引

- **requirements:** 実現したいことを整理して、issue にする。まだ作るものが決まっていない依頼。[playbooks/requirements.md](playbooks/requirements.md)
- **feature:** 振る舞いを足すか変える。設計の判断が要る変更。[playbooks/feature.md](playbooks/feature.md)
- **prototype:** 作ってみないと決まらない判断を、使い捨ての実装で決める。画面の案、操作、方式、速さを、複数の案を作って比べる。成果物は判断で、出荷するコードではない。[playbooks/prototype.md](playbooks/prototype.md)
- **bug-fix:** 報告された不具合を再現し、原因を突き止めて直す。[playbooks/bug-fix.md](playbooks/bug-fix.md)
- **refactoring:** 振る舞いを変えずに、構造を変える。名前の変更、抽出、重複の統合、移動。[playbooks/refactoring.md](playbooks/refactoring.md)
- **small-change:** 設計の判断が要らない変更。誤記の修正、設定の値の変更、依存の更新、文書の直し。[playbooks/small-change.md](playbooks/small-change.md)
- **investigation:** 今あるコードと記録を読んで、問いに答える。どう動くか、なぜこうなっているか、既にある選択肢のどちらがよいか。新しく作って比べる判断は、prototype である。[playbooks/investigation.md](playbooks/investigation.md)
- **opening-a-pr:** 変更を pull request にする。ほかの playbook の最後に行う。[playbooks/opening-a-pr.md](playbooks/opening-a-pr.md)
- **pr-follow-up:** pull request のレビューの指摘と、CI の失敗に対応する。[playbooks/pr-follow-up.md](playbooks/pr-follow-up.md)
- **verification-setup:** アプリを利用者と同じ方法で動かして確かめる手段を作るか、アプリの変化に合わせて直す。[playbooks/verification-setup.md](playbooks/verification-setup.md)
- **reflect:** 終えた作業から学びを取り出し、context か配布元へ書き戻す。「振り返って」「学びを残して」。[playbooks/reflect.md](playbooks/reflect.md)
- **correct:** 繰り返す誤りを、型、チェック、テストのような仕組みで起こせなくする。「同じ間違いを止めて」。[playbooks/correct.md](playbooks/correct.md)
- **autonomous-run:** 決めた終了の条件まで、止まらずに進める。「終わるまで続けて」「離れるので進めておいて」。[playbooks/autonomous-run.md](playbooks/autonomous-run.md)
- **pause-safely:** 作業を、続きから再開できる形で止める。「いったん止めて」。[playbooks/pause-safely.md](playbooks/pause-safely.md)
- **session-pickup:** 前の会話や別のエージェントの作業を、続きから再開する。「続きをやって」「このブランチを引き継いで」。[playbooks/session-pickup.md](playbooks/session-pickup.md)

playbook の手順が別の playbook の名前を挙げたら、この索引からそのファイルを開く。

## principle の索引

手順の途中で次の場面に当たったら、対応するファイルを全文読んでから判断する。playbook の手順が principle の名前を挙げたときも、ここから開く。  
返答には、読んだ principle と、それで変えた判断を書く。

- **prove-it-works:** 作業を終えたと言う前。[principles/prove-it-works.md](principles/prove-it-works.md)
- **fix-root-causes:** 不具合や失敗の原因を探すとき。症状を消す修正を足したくなったとき。[principles/fix-root-causes.md](principles/fix-root-causes.md)
- **smallest-change:** 変更の大きさを決めるとき。抽象化や層を足したくなったとき。[principles/smallest-change.md](principles/smallest-change.md)
- **encode-lessons:** 同じ訂正や指示を 2 回目に書いたとき。[principles/encode-lessons.md](principles/encode-lessons.md)

## 共通の規則

### todolist

- playbook を開いたら、その手順をそのまま todolist の先頭に写す。作業に固有の項目は、その後ろに足す。
- 行わない手順も消さず、`skip: <理由>` を付けて残す。

### 作業の前に読むもの

- リポジトリの `AGENTS.md` と `context/index.md` を読み、作業に関係する context を開く。
- 利用者のリポジトリの取り決めと playbook が食い違ったら、リポジトリの取り決めに従い、食い違いを返答に書く。

### 止まって尋ねる場面

- 元に戻せる作業は、尋ねずに進めて、結果を見せる。
- 実行すれば分かる事実（動き、出力、性能、見た目）は、尋ねずに確かめる。確かめるのに試作が要るなら、prototype を使う。
- 次の操作の前では止まり、利用者の明示の指示を待つ。
  - 共有のブランチへの push、pull request の取り込み、デプロイ
  - データの削除と、取り消せない変更
  - 外部のサービスへの送信。issue と pull request の作成と書き換えを含む
- 利用者だけが決められる判断（製品の方針、範囲、優先順位）は、推奨の案を添えて尋ねる。

### 判断の記録

長い作業、利用者が離れている間の作業、手順を組んだ作業では、分かれ道の判断を記録する。

- 置き場は、リポジトリの `.ai-out/YYYY-MM-DD-<主題>-decisions.md` にする。
- 1 つの判断を 1 行にし、時刻、判断、理由、根拠の在りかを書く。根拠は文章ではなく、コミット、`<path>:<行>`、pull request で指す。
- 記録するのは、2 つの案から選んだとき、確かめの結果が出たとき、方針を変えたか変更を戻したとき、先へ進めないとき。
- 追記だけにする。誤った行は書き換えず、訂正の行を足す。

### サブエージェント

- サブエージェントの数は、作業に要る分だけにする。1 つで足りる作業を分けない。サブエージェントに、さらにサブエージェントを起動させない。
- サブエージェントが返した結論のうち、返答に使う部分は自分で確かめる。

### 返答

- playbook の「返答に書くこと」を必ず含める。
- 取り消せない操作の前で止まったときは、次に利用者がする操作を 1 つ書く。

### skill と playbook の誤り

作業の途中で playbook やスキルの誤りに気づいたら、回避して先へ進めない。誤りを返答に書き、別の pull request で直す。
