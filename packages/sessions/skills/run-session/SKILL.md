---
name: run-session
description: 1 回の会話を超える作業の進め方を選び、その手順で進める。決めた終了の条件まで止まらずに進める、作業を続きから再開できる形で止める、前の会話や別のエージェントの作業を続きから再開する、作業を別のセッションに渡す、複数のワーカーに作業を配ってマージまで進める、のどれかを始めるとき、コンテキストの使用量の知らせを受けたとき、または /run-session で呼ばれたときに使う。
---

# run-session

依頼を受けたら、下の索引から playbook を 1 つ選び、そのファイルを開いて、その手順で進める。  
利用者が playbook の名前を添えたときは、その playbook を使う。

## 前提

- このスキルは、スキル run-playbook の共通の規則と principle を使う。規則をこのスキルに写さない。
  - playbook を開く前に、スキル run-playbook を開き、その「共通の規則」を読んで当てる。todolist の作り方、作業の前に読むもの、判断の 3 段、論点の尋ね方は、この playbook にも当たる。規則の索引の規則は、場面に当たったときに開く。
  - principle は、手順が名前を挙げたときに、run-playbook の principle の索引から開く。
- スキル run-playbook が無いときは、手順の中の共通の規則と principle を使う段を `skip: playbooks のパッケージが無い` とし、取り消せない操作の前では必ず止まる。
- 1 つの工程の作業（機能の追加、不具合の修正、pull request を開くなど）の手順は、スキル run-playbook の playbook にある。この playbook の手順が工程の playbook を挙げたら、スキル run-playbook の索引から開く。

## 選び方

- 索引のどれかに当てはまる作業は、その playbook を使う。
- コンテキストの使用量の知らせを受けたときは、今のコマンドの区切りで pause-safely を行う。知らせを出す閾値と手段は、利用者の構成に従う。
  - ワーカーは、pause-safely の後、次のセッションを自分で起動せず、メモの絶対パスを親に知らせて止まる。
  - 親のセッションは、pause-safely の後、delegate-work で次の親のセッションに渡す。
- 引き継ぎのメモは、リポジトリの主の作業ツリーの `.ai-out/<主題>/YYYY-MM-DD-<主題>-handoff.md` に置く。セクションは delegate-work の手順 3 にある。

## playbook の索引

- **autonomous-run:** 決めた終了の条件まで、止まらずに進める。「終わるまで続けて」「離れるので進めておいて」。[playbooks/autonomous-run.md](playbooks/autonomous-run.md)
- **pause-safely:** 作業を、続きから再開できる形で止める。「いったん止めて」。[playbooks/pause-safely.md](playbooks/pause-safely.md)
- **session-pickup:** 前の会話や別のエージェントの作業を、続きから再開する。「続きをやって」「このブランチを引き継いで」。[playbooks/session-pickup.md](playbooks/session-pickup.md)
- **delegate-work:** 作業を別のセッションに渡す。引き継ぎのメモか、ワーカーへの指示を作る。「この作業を別のセッションに渡して」。[playbooks/delegate-work.md](playbooks/delegate-work.md)
- **coordinate-workers:** 依存を並べた複数の作業をワーカーに配り、マージと片付けまで繰り返す。「この issue 群をワーカーに配ってマージまで進めて」。[playbooks/coordinate-workers.md](playbooks/coordinate-workers.md)

playbook の手順が別の playbook の名前を挙げたら、この索引からそのファイルを開く。

## 返答

- playbook の「返答に書くこと」を必ず含める。
- 取り消せない操作の前で止まったときは、次に利用者がする操作を 1 つ書く。
