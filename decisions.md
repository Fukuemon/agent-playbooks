# Decisions — skill / rule 著作の判断記録

skill / rule / subagent を **どう作るか** の非自明な判断と「今後こうする」を残す。背景を知らない提案・issue で逆戻しされるのを防ぐのが目的。

**ここに書くもの**: 再学習コストが高く、diff では追えない割り切り (token コスト・ツール制約・スコープの線引き)。
**ここに書かないもの**: プロダクトの技術判断は [adr/](adr/) へ。skill 連鎖の構造は [architecture.md](architecture.md) へ。個々の変更履歴は git log で追う。

書式は 1 判断 1 セクション、**新しいものを上に**積む。各セクションは `背景 / 判断 / 理由 / 今後` の 4 項目。`今後` に「今後こういう提案は却下 / こう作る」を必ず書く。

---

## 2026-07-27 closeout は「検査 + 削除 PR の自動起票」で担保し、自動削除はしない (workflow は無ければコピー配布)

- **背景**: 消費 repo (kufu-apps) で close 済み issue の spec が 9 件残存していた (kufu-apps#31)。closeout 手順は存在したが **実行の担保が手順側に無い**。kufu-apps は「残存検査スクリプト + issue close 契機の削除 PR 自動起票」の 2 段構えで解決し実運用まで確認済み (issue #7)。同じ構成を共有プロセス層へ展開する。
- **判断**: ① **自動削除はしない**。削除の前提 (durable 成果が design / context / ADR へ sync 済みか) は機械判定できないため、bot は削除 PR を起票するだけで、削除の可否はマージ可否で人が決める。② 検査は `scripts/check-specs-residue.sh` として **実ファイルコピー配布** (`hooks/` / `generate.sh` と同じ列)。入口は `sdd-template.mk` の `check-specs` target。③ 検査の CI 常設は `spec-residue.yml` (デフォルトブランチへの push + 毎週 + 手動)。**PR ゲートにはしない** — 別 PR で清算する運用だと「issue は閉じたが spec は残っている」窓の間、無関係な PR が落ちるため (ゲート化の条件は workflow 末尾にメモ)。④ workflow 2 本は `templates/consumer/.github/workflows/` に置き、link.sh は **無ければコピー** (`lefthook.yml` と同じ「初期値。以後は消費側が所有」)。消費 repo には既存 workflow があるため一括同期 (rsync) には含めない。⑤ 固有値は外出し: spec dir は `context/project.yml` の `paths.spec_dir` の固定部分、repo 名は `gh repo view` (env `SPECS_CHECK_REPO` で上書き可)、ADR リンクは削除し closeout 手順は skill 相対参照にした。⑥ 検査は **終了コード 2 (検査不能) を合格にしない** — gh の認証切れ・権限不足・想定外の state で黙って通ると残存を見逃す。stderr を state に混ぜない (gh の通知混入で CLOSED を取りこぼす)。
- **理由**: kufu-apps #31 の清算では未転記の設計情報が 6 件見つかり、うち 1 件は ADR と実装が矛盾していた。自動削除していれば失われていた。「toil だけ自動化し判断は人に残す」が設計の要点。workflow を一括コピー配布にしない理由は、消費 repo の既存 workflow を silent に壊すリスクが「テンプレ更新の追随しやすさ」より重いため (更新は差分レビューで取り込む)。
- **今後**: 「bot に削除まで任せる」提案は却下 (sync 済み判定が機械化できるようになるまで)。検査の終了コード 2 を 0 扱いにする / `|| true` で通す提案も却下 (ゲートが無意味になる)。workflow を `copy_tree` に移す提案は、消費 repo の workflow 衝突を検出する仕組みができてから再検討する。

## 2026-07-26 root rule から 2 大契約を on-demand reference へ移し、常時ロードをポインタだけにする

- **背景**: root rule (`.rulesync/rules/CLAUDE.md` → `AGENTS.md` / `CLAUDE.md`) が 159 行あり、その約半分は `Spec Workflow Contract` (SDD の運用契約 ≒ 60 行) と `Skill 共通契約` (skill 著作規約 ≒ 15 行) だった。どちらも **使う場面が限られる** (spec-\* skill 起動時 / skill を書くとき) のに毎ターン全文ロードされていた。`Setup` 節は README の「はじめかた」「消費 repo へ接続する」とほぼ重複していた。
- **判断**: ① `Spec Workflow Contract` を `spec-lifecycle` の `references/spec-contract.md`、`Skill 共通契約` を `rulesync-sync` の `references/skill-contract.md` へ移し、root rule には 1 行のポインタだけを残した。参照側 (spec-\* skill / context-harvest / design-doc / styleguide-documents / spec-reviewer subagent / architecture.md / check-skills.sh) の「`AGENTS.md` の `<契約名>`」表記を **skill 相対の参照** (`spec-lifecycle` の `references/spec-contract.md`) に一括で書き換えた。② `Setup` 節は削除し、変更ループ (`.rulesync/` 編集 → `make generate` → `make check` → commit) と共有プロセス層の commit 順序だけを「共有プロセス層を変更するとき」に圧縮して残した (初期適用手順は README が正本)。③ `Documents (正本)` を表に、そのほかの節も命令形で圧縮。root rule は 159 → 約 95 行。
- **理由**: 2026-07-24 の prose-rhythm 統合と同じ「常時ロードはポインタ / 本文はオンデマンド Read」の適用。skill 相対参照 (`<skill>` の `references/<topic>.md`) を選んだのは、provider ごとに実 path が変わる (`.claude/skills/` / `.agents/skills/`) ため。生成物 path を直書きすると provider 間で腐る。subagent (`spec-reviewer`) だけは skill 解決を持たないので、Claude Code の実 path を 1 箇所に明記した。
- **今後**: root rule に規範の**本文**を足す提案は却下する (置き場は該当 skill の `references/`)。root rule に置いてよいのは、正本の地図・禁止事項・承認の取り方・出力形式など「毎ターン効かせたい短い規律」のみ。契約を移すときは参照側の表記も同 PR で書き換える (`grep -rn '<契約名>'` で全数確認する)。

## 2026-07-26 RTK は開発者ごとの global 設定として推奨し、repo の hook には登録しない

- **背景**: bash 出力を圧縮して token を削る RTK (Rust Token Killer。`git status` → `rtk git status` に PreToolUse hook で書き換える CLI プロキシ) を取り入れたい、という要望。導入形態は ① repo の `.rulesync/hooks.json` に PreToolUse hook を登録して配布、② 各開発者が `rtk init -g` で `~/.claude` に入れる、の 2 通り。
- **判断**: ② を採る (ユーザー判断)。repo 側の hook には登録せず、導入手順と注意点を `dev-commands` の `references/rtk.md` (共有プロセス層なので消費 repo にも symlink で届く) に置き、README と `templates/context/toolchain.md` は 1 行ポインタ。あわせて repo 側で 2 点だけ整合を取った: ① `.rulesync/permissions.json` に **読み取り系の `rtk` サブコマンドのみ** allow (`rtk gain` / `rtk git status|diff|log|show` / `rtk ls|tree|cat|read|grep|rg|find|test`)。書き込み系 (`rtk git push` 等) は素の命令と同じく都度承認。② `hooks/protected-branch/pre_tool_use.py` に `strip_wrappers()` を追加し、`rtk` 前置を剥がしてから git サブコマンドを判定する。
- **理由**: repo hook 方式は、rtk 未インストールの環境 (CI / クラウドエージェント / 他メンバー) で hook が空振り or 失敗し、global 導入済みの開発者とは二重に書き換えが走る。RTK は **効率化であって workflow の前提ではない**ので、成立条件を repo 側に持ち込まない。一方 guard の `rtk` 前置剥がしは必須 — 剥がさないと `argv[0] != "git"` で protected branch ガードが素通りし、`rtk git commit` が main に通ってしまう (セキュリティ上の穴)。`rtk:*` の一括 allow を採らないのは、rtk が任意コマンドのプロキシであり、一括許可すると `push` / `rm` の承認ゲートを迂回できるため。
- **今後**: 「repo の hooks.json に rtk hook を入れよう」という提案は、消費 repo 全員の環境に rtk が入っている前提が確認できてから再検討する。`rtk:*` を一括 allow する提案は却下 (承認ゲートの迂回)。ラッパーを増やすとき (`nice` / `time` / 他プロキシ) は `WRAPPERS` に足し、guard のテストを同 PR で回す。

## 2026-07-25 選択導入型 skills/ にも Skill 共通契約を適用し、effective-go を日本語の単一規約として再構成

- **背景**: `skills/effective-go` は外部 repo (openshift/hypershift) からの移植のままで、英語 description・非正規セクション名など Skill 共通契約に非準拠、かつ `check-skills.sh` の走査対象外だった。内容面では、自家製の運用規約 (5 ファイルパターン・1 パッケージ 1 公開関数等) が「Go Style Guide」として公式規範と無区別に提示され、公式 (形でなく「見つけやすさ」基準のみ・`types`/`interfaces` の種類別命名に否定的) との緊張があった。godoc reference は「公式を読め」だけで実質が薄かった。
- **判断**: ① Skill 共通契約の適用範囲を「`.rulesync/skills/` と選択導入型 `skills/` の両方」と明記し、`check-skills.sh` の走査対象に `skills/*/` を追加 (effective-go は reference 型例外)。② 日本語で全面再構成し、**文書全体を「本テンプレートの Go 規約」として一本化** — 公式との整合は著作時に済ませ、実行時の優先判定を持たない。当初は「公式の推奨 / house rule」の 2 層分離を実装したが、同日中に一本化へ変更 (ユーザー判断)。公式より意図的に厳しい 2 箇所 (公開面の最小化・パッケージ変数禁止) にのみ「本規約独自 — 公式より厳しい」と注記し、逸脱をプロジェクト判断で扱えるようにした。③ 内容の吟味結果を反映: 公式規範 (ファイルサイズと発見しやすさ / black-box テストパッケージ / consumer 側 interface / stutter 禁止 / util・common 禁忌) を出典付きで記載し、types.go に dumping ground 化への警告を追加。godoc は公式 Go Doc Comments の実体 (宣言名開始・完全文・doc.go の根拠・Deprecated:・1.19 リンク記法) を記載する形に書き直した。
- **理由**: 2 層分離 + 「衝突したら公式優先」の実行時ルールは、エージェントに書かれたルールを使用時に二度疑わせる (判断の委譲) ため却下。スタイルガイドは全体が規範であるのが通常の契約で、出典は信頼性の担保として注記に留める。「本規約独自」の注記だけは、レビューで「公式違反」と「独自ルールからの逸脱」の重みを変えられる実益があるため残した。
- **今後**: 選択導入型 skill も契約準拠で書く。規約の中に実行時の優先判定 (「衝突したら X を優先」) を持ち込む提案は、著作時に整合を済ませるべきものとして却下。公式より厳しいルールを追加するときは「本規約独自」注記を付ける。消費 repo の旧英語版は `npx skills add` 再実行で更新する。

## 2026-07-24 コードレビューを観点別 subagent 4 本 + 敵対的姿勢 + degrade 構成にする

- **背景**: レビュー観点は spec / 文書側 (`spec-reviewer` の 7 観点 + Default-FAIL) に偏っており、コード差分は `multi-agent-review` の固定 rubric 5 行を全部入り 1 プロンプトで外部 CLI に同報するだけだった。俯瞰的な観点 (依存方向・境界・責務の置き場・生成物編集) が無く、外部 CLI 不在の環境ではコードレビュー自体が回らなかった。参考 repo (Fukuemon/skills) は観点別 `review-*` subagent + 敵対的姿勢 + degrade 設計で解決している。
- **判断**: ① `review-{architecture,quality,security,performance}` subagent を新設 (Read / Grep / Glob のみ)。参考 repo の Go / クリーンアーキ固有条件は直書きせず、`context/architecture.md` / `context/testing.md` / `context/infrastructure.md` / `project.yml` への参照に汎用化。② 敵対的レビュー姿勢 (「性弱く見逃さない。好意的解釈をせず、迷ったら指摘に倒す。問題のみ報告」) を全 review subagent と `review-prompt.md` の前文に固定 — 文書側 Default-FAIL のコード版。③ 観点の選択は `review-routing.md` の対象差分シグナル表で行い、小さい差分で全観点を回さない (quality のみ常時)。④ degrade 規則: 外部 CLI 2 台以上 = 並列クロスチェック → 1 台 → 0 台なら Claude の `review-*` subagent に degrade → subagent も無ければフォールバック rubric。孤立環境でも観点別レビューは回る。
- **理由**: 観点の正本を subagent 定義に置くのは spec-reviewer と同じ既定路線 (2026-07-07 決定)。外部 CLI 向けには定義本文をプロンプトにインライン注入する (CLI は subagent を spawn できないため)。レビュー姿勢の 3 行を各 subagent に再掲するのは「正本 1 箇所」原則の例外だが、subagent は実行時に他文書を読めない自己完結プロンプトであり、参照渡しでは姿勢が効かないため許容する。
- **今後**: 観点の追加・変更は `review-*.md` のみを編集し、routing 表には行を足すだけにする (skill 側に観点を再記述しない)。stack 固有の検証条件 (ORM / framework 名) を subagent に直書きする提案は却下 — `context/` の規約を育てて参照させる。

## 2026-07-24 spec は issue close 時に削除する (closeout)。sync を唯一の救出点として精度を上げる

- **背景**: 従来は sync 後の spec を「決定時スナップショット」として永続させていたが、残すと design 側に spec への索引が積もって認知負荷が上がり、現行実装と食い違った古い spec がドリフトの温床になる (ユーザー提案 2026-07-24)。決定経緯・受け入れ基準は issue / PR / git history に残るため、削除しても追跡可能。
- **判断**: ① 正本境界にライフサイクル最終段「issue close 後 (closeout): spec を削除する」を追加し、手順・前提条件 (sync 完了 / issue closed / open な派生 issue なし / prompts 完了) を `spec-lifecycle/references/closeout.md` に置く。PR merge 後の案内は `workflow-git` の pr-workflow に接続。② 削除前提に耐えるよう sync の精度を強化: 「変更提案」行だけでなく **解決済みの論点を全行棚卸し**し、各行に「反映先 or spec で閉じる」の判定を必須化。**選択肢を比較して決めた判断は影響範囲が小さくても ADR 化を既定**とする (削除後に「なぜこうしたか」を再現できる場所が ADR しかないため)。③ 取りこぼし検査を二重化: `spec-reviewer` の正本境界観点に「未判定の論点行 = NEEDS_WORK」を追加し、closeout の最終刈り取りを最後の検出点とする。④ impact-index の `source_refs:` は closeout で ADR / feature doc に差し替える。
- **理由**: 「durable な情報は design が正本、spec は作業文書」という既存の正本境界の論理的帰結。スナップショットを残す方式は「二重正本を防ぐ」ためのリンク規律を永続的に要求するが、削除すればその規律ごと不要になる。git history が保存庫なので情報は失われない。
- **今後**: 「削除せずアーカイブ dir に移す」提案は、索引が残り認知負荷が下がらないため却下。sync 未完のまま削除する運用は情報喪失なので、closeout の前提条件を緩める提案も却下。closeout で ADR 未起票の意思決定が頻繁に見つかるようなら、sync の棚卸し手順側を先に疑う。

## 2026-07-24 contract (AGENTS.md) を agents.md ベストプラクティスに沿って整理

- **背景**: agents.md (公式) の推奨は「エージェントが実行を試せるコマンド・セキュリティ考慮・PR 規約を root の Markdown で」。照合すると、変更ループ (編集 → generate → check) が節をまたいで分散し、Security 節が無く、一方で project.yml へのポインタが複数節に重複していた。本テンプレはサンプルなので repo 自身の固有値の記入はしない (ユーザー判断)。
- **判断**: ① Setup 直後に「共有プロセス層を変更するとき: `.rulesync/` 編集 → `make generate` → `make check` → 生成物ごと commit」の 1 行を追加。② `Security` 節 (secret / 個人 PC 絶対パスの禁止 + infrastructure.md への委譲) を追加。③ 重複していた `Repository / Commands / Naming` 節と `Decision Priority` 節を削除 (冒頭の固有値段落と project.yml に集約済み。dev-commands への導線は Skills 表が持つ)。④ workflow-git の「先に読むもの」にあった存在しない節への参照 (`Repository Reference Rules`) を project.yml の `repos` / `labels` に修正。
- **理由**: contract は消費 repo へ symlink 共有されるため固有値は書けない。汎用のまま追加できるもの (変更ループ / Security) だけを足し、ポインタの重複は「正本 1 箇所 + 1 行参照」の原則で畳んだ。
- **今後**: contract に節を足すときは agents.md の推奨セクション (コマンド / スタイル / セキュリティ / PR 規約) との対応を確認する。project.yml へのポインタを複数節に再掲する提案は却下。

## 2026-07-24 読み物向けライティング規範を styleguide-documents の reference として統合 (常時ロードはポインタのみ)

- **背景**: 外部の skill (gist: k16shikano/eb2929f13ed19c97188393d297be8432 の cognitive-rhythm-writing) を styleguide として取り入れ、読み物系の文章を書くとき必ず読ませたい、という要望。当初は独立 skill `styleguide-prose` として導入したが、参考 repo の skill 化基準「人間が単独で起動する価値があるか」に照らすと、文書品質のハブは `styleguide-documents` 1 つで足り、起動トリガー語も description 側に足せるため、同日中に reference 統合へ変更した (ユーザー指示)。
- **判断**: ① 規範本文を `styleguide-documents/references/prose-rhythm.md` として統合 (原文をほぼそのまま維持し、100 行超のため冒頭に目次。原文の誤参照 1 箇所〔拍がない→点検手順 3〕は 4 に修正)。独立 skill は置かない。② 適用対象を「読み物として読ませる文章 (記事 / 解説 / 章立ての文章)」に限定し、spec / ADR / context 等の技術文書は**対象外**と明記 (5 原則の曖昧さの排除と衝突するため)。③「必ず読ませる」は、常時ロードされる contract の Skill 共通契約と `styleguide-documents` 冒頭・`いつ使うか` の必読注記による 2 経路のポインタで実装。規範本文 (約 130 行) の常時ロードは採らない。
- **理由**: 常時ロード rules は毎ターン token を消費する (2026-07-07 決定)。ポインタ (数行) を常時ロードし本文はオンデマンド Read にすれば、「必ず読む」導線と token コストを両立できる。原文を書き換えない理由は、この規範自体が語彙・例文単位で自己参照的に設計されており (漏出テスト等)、部分的な言い換えが規範の整合を壊すため。
- **今後**: 読み物系の文書を書く skill を将来追加する場合は「先に読むもの」に `styleguide-documents` (+ prose-rhythm.md) を明記する。規範本文を要約・圧縮する提案は却下 (2026-07-07「references は常時ロード rules ほどの圧縮を強制しない」)。独立 skill への再分離は、読み物執筆が独自の実行フロー (phase / 停止条件) を持つようになったときのみ再検討する。

## 2026-07-24 issue の status ラベル遷移 + 状態遷移コメントを簡約 3 状態で導入 (イベント記録は不採用)

- **背景**: 参考 repo は要求〜実装の節目で 6 状態の状態ラベル遷移・状態遷移コメント・イベント記録コメント (FourKey リードタイム計測の節目) を issue に残す。本テンプレは進捗の正本が spec 内の `## 設計フェーズ状況` 表 + WIP commit のみで、issue だけを見ても設計の進捗が見えなかった。
- **判断**: ① `status:designing / status:ready-to-implement / status:implementing` の **3 状態に簡約**して `project.yml` の `labels` に追加 (6 状態は企画/開発/検証の分業前提のため採らない)。② 遷移は 3 節目のみ: scaffold 開始 (spec-lifecycle) / 最終 gate レビュー済 (spec-lifecycle) / 実装 prompt ステップ 0。close は PR の `Closes #N` に任せラベル操作しない。③ 遷移のたびに状態遷移コメントを 1 件残す (正本: `workflow-git/references/issue-status.md`)。④ **イベント記録 (リードタイム計測) は不採用** — 個人利用前提で計測の需要がないため (ユーザー判断 2026-07-24)。
- **理由**: spec の表 (phase 単位の詳細) と issue ラベル (粗い要約) の 2 層にし、同じ粒度を二重管理しない。遷移点を 3 つに絞ることで、承認の取り方 (3 択) を挟んでも運用が重くならない。
- **今後**: チーム利用でリードタイム計測が必要になったら、イベント記録コメント (固定文字列) と集計 skill (参考 repo の productivity-report 相当) をセットで再検討する。状態を 6 値に増やす提案は分業体制が実際に生まれるまで却下。

## 2026-07-24 参考 repo から 7 機構を追加移植 (突合ゲート / 派生 issue / frontmatter 契約 / 読み取り索引ほか)

- **背景**: 参考 repo (Fukuemon/skills) の網羅調査で、既取り込み分 (phase 配列駆動・選択的 gate 等) 以外に移植価値の高い機構が特定された。移植にあたり Anthropic 公式の skill 著作ベストプラクティス (SKILL.md は目次役・references は 1 階層・100 行超は冒頭に目次・チェックリスト + 検証ループ・用語は 1 つに統一) を確認し、これに沿って構成した。
- **判断**: 次の 7 機構を移植した。用語は平易な日本語に変換している (括弧内が参考 repo での呼称):
  1. **実装との突合ゲート** (設計時ドリフト突合): scaffold で増分判定 → clarify 冒頭で spec × 実装 × ADR × context を 1 回突合し、食い違いはユーザーが正を確定 (`phase-scaffold.md` §7 / `phase-clarify.md` §0)
  2. **差分修正モード** (修正デルタモード): prompts 生成の最初に「変更対象の既存実装コードが在るか」で新規実装 / 差分修正を判定し、差分修正では機能全体の再実装・migration 再作成を禁止 (`phase-prompts.md`)
  3. **派生 issue + 品質ラベル**: 前段 phase の取りこぼし (要求漏れ / 設計漏れ) は進行中 issue に吸収せず `quality:requirement-gap` / `quality:design-gap` 付き派生 issue を起票、双方向リンク + 発覚理由必須 (`workflow-git/references/derived-issue.md`、労力の正本は project.yml `labels`)
  4. **prompt の機械可読 frontmatter**: `phase / seq / target / issue / depends_on` を必須化し、`depends_on` は実依存列挙 (phase 隣接で近似しない)。将来の実装オーケストレーション (jisso-run 相当) の前提 (`prompt-rules.md` / `prompt-template.md`)
  5. **読み取り索引** (読み取りコントラクト / impact-index): `context/impact-index.yaml` の「索引 → 該当 feature の read: だけ読む」契約。sync phase と context-harvest が索引を育てる
  6. **prompt 検証 hook 強化**: `hooks/spec/validate_prompts.sh` に frontmatter 5 キー検査と探索誘発表現の grep 検出を追加
  7. **承認の取り方** (承認プロンプト規約) と **受け入れ再検証** (sekkei-pickup の引き取りゲート): 前者は contract の新節 (Y/N 禁止・3 択以上・既定を進める側にしない)、後者は spec-lifecycle intake での intake-checklist 再検証 + 差し戻し
- **移植時に落としたもの**: GitLab 固有の milestone 継承・状態ラベル遷移・registry.md 依存 (テンプレは registry 未導入のため、既存ファイル特定は spec の差分の名指しに依拠)。認可マスター突合は authorization appendix の範囲として汎用化せず見送り。
- **理由**: いずれも「増分開発」「後戻り要求」「token 削減」というテンプレの弱点を突く機構で、phase レジストリ構造にそのまま載る。呼称の日本語化は 2026-07-07 決定 (外来語を平易な日本語に) に従う。
- **今後**: 読み取り索引は「索引が実態とずれる」のが最大の失敗モード。sync / context-harvest の索引更新ステップを外す提案は却下。品質ラベルの付与先を変更元 issue 側に広げる提案は「派生側にのみ付与」の原則を崩すため却下。

## 2026-07-24 固有値の正本を context/project.yml 1 本に統合 (project.md / project-config.yaml を廃止)

- **背景**: 2026-07-23 に機械可読値を `project-config.yaml`、散文の規約を `project.md` に分ける 2 ファイル構成を採ったが、実際には project.md の内容 (Repository Map / Naming / Quick Commands / Label Policy / Source of Truth / Templates / Decision Priority) もほぼ全て構造化可能な値で、「どちらに書くか」の判断コストと参照の二重化 (契約や skill が両ファイルを指す) が残った。参考 repo (Fukuemon/skills) も固有値は `project-config.yaml` 1 本で、散文の別ファイルを持たない。
- **判断**: `context/project.yml` 1 本に統合 (ユーザー指定の命名)。旧 project.md の全セクションを yaml キーに写像した: Repository Map→`repos` (layout はブロックスカラー) / Naming→`naming` / Quick Commands→`commands` / Issue Tracker→`tracker` / 対象ドメイン→`domains` / Label Policy→`labels` (axes + minimum) / Source of Truth→`paths` / Templates→`templates` / Decision Priority→`decision_priority`。説明的な文はキー横のコメントで持つ。契約・skill・context/\*.md・テンプレの参照は全て `project.yml` の該当キー名 (例: 「Quick Commands 表」→「`commands`」) に更新した。
- **理由**: 正本 1 ファイル・キー参照 1 形式にすることで、「同じ規範を複数ファイルに再掲しない」原則を固有値にも適用できる。yaml コメントで散文の説明力は十分保て、skill 側は常にキー名で決め打ち参照できる。
- **今後**: 固有値の追加はまず `project.yml` のキー追加で表現できないか検討する。「散文用に project.md を復活させたい」提案は二重管理の再発として却下 (長い説明が必要なら context/\*.md の該当 topic に置き、project.yml からコメントで参照する)。

## 2026-07-24 rulesync を 14.2.0 に pin する (fix-codex-config.sh は維持)

- **背景**: `scripts/generate.sh` は `rulesync@latest` を呼んでいたため、上流リリースで生成物が変わると repo 側の変更なしに drift 検査が壊れ、消費 repo でも generate 結果の再現性が無かった (実際に 14.2.0 で `.codex/config.toml` に `approval_policy` 等の新キーが増え、HEAD 生成時との差分が発生した)。あわせて fix-codex-config.sh の要否を再調査した: 14.2.0 の素の出力は依然 `default_permissions = "rulesync"` と `":minimal" = "read"` を含む `[permissions.rulesync.filesystem]` block を出力しており (2026-07-08 決定の除去対象と同形)、normalizer は no-op になっていない。`extends = ":workspace"` が併記されるようになったため阻害が解消された可能性はあるが、Codex Desktop での実機確認はできていない。
- **判断**: ① `scripts/generate.sh` の rulesync を `14.2.0` に pin し、更新は動作確認込みの bump commit で行う。② `fix-codex-config.sh` は維持する (削除条件 = Codex Desktop で素の 14.x 出力のまま workspace read が通ることの実機確認)。
- **理由**: pin により generate は入力 (`.rulesync/`) だけの関数になり、CI の drift 検査が本来の目的 (正本と生成物の同期) だけを検査できる。normalizer の削除は「生成物の見た目」でなく「実機挙動の確認」を条件にする — 適用後の config だけ見て no-op と誤認しかけた経緯があるため。
- **今後**: rulesync bump 時は `.codex/config.toml` の permissions 出力の変化と workspace read への影響を確認する。`@latest` に戻す提案は再現性の喪失を理由に却下。

## 2026-07-23 参考 repo の sekkei / youken 構成から phase 配列の設定駆動化・選択的 gate・project-config.yaml を取り込む

- **背景**: 参考 repo (Fukuemon/skills) の `sekkei` は phase の集合・順序を `context/project-config.yaml` の `sekkei.phases` で外部化し、`gate: true` の phase のみレビューして残りは次 gate で累積レビューする (token 節約)。`youken` は公開前のトラッカー操作をユーザー承認まで禁止する起票ゲートを持つ。本テンプレの `spec-lifecycle` は phase 固定・全 phase レビューで、固有値は `context/project.md` (散文) のみだった。さらに `phase-guide.md` には選択的 gate の記述が既にあり、SKILL.md の「全 phase レビュー」と不整合だった。
- **判断**: ① 機械可読な固有値 (product / repos / tracker / domains / spec.phases / glossary) を `context/project-config.yaml` に分離し、散文の規約 (命名 / コマンド / Label Policy / 正本パス) は `project.md` に残す。tracker / domains は yaml を正本とし、project.md・各 skill は参照に畳む。② `spec-lifecycle` に phase レジストリ (識別子 / kind / gate) を置き、実行列は `spec.phases` が決める。gate は既定で clarify / track / prompts の 3 箇所、非 gate phase は次 gate で累積レビュー。ハンドオフ基準・停止テンプレは `references/handoff.md` に分離 (SKILL.md 200 行制約)。③ `spec-requirement` に youken 方式の起票ゲート (承認前のトラッカー操作禁止・「そのまま進めて」でも緩めない) と完了時の案内を追加。
- **理由**: phase の採否・順序をデータにすることで、消費 repo ごとの差 (diagram 不要・独自 phase 追加等) を skill 本体の編集なしに吸収できる。全 phase レビューは fresh-context evaluator の起動コストが phase 数ぶん掛かるが、累積 gate なら同じカバレッジを 3 回で得られる。yaml / md の分割は「skill が分岐に使う値」と「人が読む規約」で参照特性が違うため。
- **取り込まなかったもの**: `review_scope` (観点別レビュー委譲) は、レビュー観点の正本を `spec-reviewer` subagent 1 本に集約した 2026-07-07 決定と競合するため見送り。youken の CRITICAL / HIGH / MEDIUM 件数閾値は、`spec-review` が PASS / NEEDS_WORK の二値で severity 体系を持たないため見送り (導入するなら subagent 定義の出力契約ごと変える必要があり、コストに見合わない)。
- **今後**: phase を追加する場合はレジストリに 1 行 + `references/phase-*.md` を足し、`spec.phases` 既定列を更新する。「全 phase でレビューに戻す」提案は token コストを理由に却下 (必要なら消費 repo が gate を増やすのではなく、レビュー観点を subagent 側で強化する)。機械可読値を project.md に再掲する提案は二重管理を招くため却下。

## 2026-07-14 rulesync 後処理を hooks/ と同じ「実行時参照は実ファイルコピー」原則に揃える

- **背景**: 2026-07-12 の Make target 集約で `scripts/fix-cursor-cli.sh` / `fix-codex-config.sh` / `fix-claude-settings.sh` を追加したが、`link.sh` はこれらを (`.rulesync/` と同様の) live symlink として配布していた。`templates/consumer/sdd-template.mk` の `generate` target はこれらのスクリプトを実行時に呼ぶため、2026-07-07 決定の「repo を clone しただけの環境で動くか」という判断基準に反し、link.sh を再実行していない bare clone (CI / クラウドエージェント) で `make -f sdd-template.mk generate` が `No such file or directory` で失敗する欠陥があった。また 3 スクリプトの実行列 (`rulesync generate` → 3 normalizer) が Makefile / sdd-template.mk / check-generated.sh の 3 箇所に手動列挙で複製され、同期漏れのリスクがあった。
- **判断**: ① `scripts/generate.sh` を新設し、生成シーケンスを 1 箇所に集約する。Makefile / sdd-template.mk / check-generated.sh はすべてこれを呼ぶ。② `scripts/generate.sh` と 3 つの `fix-*.sh` は hooks/ と同じく **実ファイルコピーで配布**し、消費 repo が commit する (CANDIDATES symlink から除外)。③ `check-generated.sh` は git diff ベースの検査に戻し (未 commit 検出も含む)、独自の before/after ディレクトリスナップショット方式は廃止する。④ `link.sh` の tracked 宛先ファイル上書きは、コメントどおり削除せず `.pre-link.bak` に退避してから symlink へ置換する (未追跡ファイルと同じ扱いに統一)。
- **理由**: 2026-07-07 決定の原則 (「実行時に参照されるものは実ファイルコピー」) を rulesync 後処理スクリプトにも一貫適用することで、clone-and-go を壊さない。生成シーケンスの単一化は、provider 固有ワークアラウンドを増減する際の同期漏れ (2026-07-12 決定の「今後」で認識されていたリスク) を構造的に解消する。git diff ベースの drift 検査は、手製スナップショット比較より安価かつ untracked ファイル検出を両立できる。
- **今後**: 新しい provider normalizer を追加する場合は `scripts/generate.sh` に 1 行足すだけでよく、Makefile / sdd-template.mk / check-generated.sh を個別に触らない。「正規化スクリプトを symlink 配布に戻す」提案は clone-and-go の破綻を理由に却下。

## 2026-07-12 共通 workflow とプロジェクト選択型 skill を配布経路で分ける

- **背景**: Effective Go のような言語・framework 固有 skill は、対象外プロジェクトにも rulesync で常時配布すると skill listing と生成物を不要に増やす。
- **判断**: 全プロジェクト共通の開発プロセスは `.rulesync/skills/` から rulesync 配布し、選択型 skill は `skills/` に置いて消費側が `npx skills add <repo> --skill <name>` で導入する。`skills/effective-go` を最初の選択型 skill とする。
- **理由**: workflow contract の一貫性は維持しながら、技術スタック固有の知識だけを opt-in にできる。`npx skills` は repository 内の特定 skill と複数 agent への導入を扱える。
- **今後**: skill 追加時は「全消費 repo で必須か」を境界判定に使う。選択型 skill を `.rulesync/skills/` に重複配置しない。

## 2026-07-12 rulesync 後処理を Make target に集約して消費 repo に配布する

- **背景**: rulesync 後に Cursor / Codex 固有の正規化が必要で、Claude Code の commit / PR attribution も無効化したい。個別 script の手動列挙は追加漏れを起こしやすい。
- **判断**: template 側は `make generate`、消費側は配布する `sdd-template.mk` の `make -f sdd-template.mk generate` を唯一の実行入口とする。Claude は公式の `attribution: {commit: "", pr: ""}` を生成後に適用する。
- **理由**: rulesync と provider 固有後処理を原子的に実行でき、既存の消費側 Makefile と target 名を衝突させず配布できる。
- **今後**: provider 固有 workaround の追加・削除は両 Make target と drift check を同時に更新する。

## 2026-07-08 Codex config は rulesync generate 後に workspace read を阻害する permission だけ正規化する

- **背景**: `rulesync generate` が `.codex/config.toml` に `default_permissions = "rulesync"` と `[permissions.rulesync.filesystem]` (`":minimal" = "read"`) を出力し、Codex Desktop で repo root は cwd として見えているのに `specs/` / `context/` / `.rulesync/` などの通常ファイル read が `Operation not permitted` になるケースが発生した。rulesync の現行 schema では Codex Desktop の workspace read policy を安定して表現できない。
- **判断**: `scripts/fix-codex-config.sh` を追加し、`rulesync generate` 後に `default_permissions = "rulesync"` と `[permissions.rulesync.filesystem]` block だけを除去する。MCP / hooks / network permissions は残す。`make generate`、`scripts/check-generated.sh`、`rulesync-sync` の生成手順、`link.sh` の消費 repo 案内に組み込む。
- **理由**: `.codex/config.toml` を手編集すると次回 generate で戻る。一方、permissions feature 全体を外すと Claude / Cursor など他 provider の権限生成にも影響する。既に Cursor CLI 互換化で post-generate normalizer を使っており、同じ層で Codex 固有差分を吸収するのが最小影響で監査しやすい。
- **今後**: Codex の workspace read policy を rulesync 側で直接表現できるようになるまでは normalizer を維持する。「生成物を手で直す」「permissions feature を丸ごと外す」提案は却下。rulesync の対応が入ったら normalizer の削除を再検討する。

## 2026-07-07 消費 repo への配布は 2 層 (ソース = live symlink / hooks = 実ファイルコピー) + .template-version で追跡

- **背景**: 消費 repo への配布形式として、参考 repo (Fukuemon/skills) の dist worktree symlink 方式 (消費側 commit ゼロ) に寄せるかが論点になった。また hooks/ を symlink 配布すると、commit 済みの `.claude/settings.json` が実行時に参照する `hooks/...` が clone しただけの環境 (CI / クラウドエージェント / link.sh 未実行マシン) に存在せず、protected-branch ガードや文書検証が **silent に効かなくなる** (参考 repo に「hook が数ヶ月 no-op でも silent fail で気付けなかった」という前例がある)。
- **判断**: ① ソース層 (`.rulesync/` の skills / contract / subagents) は従来どおり live symlink (双方向編集・未追跡)。② 実行時に参照される層 (`hooks/`) は link.sh が **実ファイルとしてコピーし消費側が commit** する。③ 消費側 git hooks は `templates/consumer/lefthook.yml` を初期値として「無い場合だけ」コピー (テンプレ著作用の check-skills は含めない。以後は消費側所有)。④ 配布元テンプレの commit SHA を `.template-version` に記録し、更新は link.sh 再実行 → 差分 commit で取り込む。
- **理由**: 判断基準は「repo を clone しただけの環境で動くか」。生成物と hook 実体が commit されていれば CI / クラウドエージェント / 新規メンバーの clone で即座に効く。dist worktree 方式は「消費側が rulesync を持たない」制約を中央で吸収するためのもので、消費側でも rulesync generate を回す本テンプレの設計では利点が薄い。symlink 経由のスクリプト実行は sandbox で拒否されうる点、commit された実ファイルは PR diff で監査できる点も commit 方式を後押しする。
- **今後**: 「hooks も symlink に戻す」提案は clone-and-go の破綻と silent fail を理由に却下。dist worktree symlink への移行は「消費 repo が増えて再 generate commit が苦痛になった」時点で再検討する。消費側 lefthook.yml へのテンプレ著作用検査の追加は却下 (消費側の関心事ではない)。

## 2026-07-07 hook command は project root へ cd してから相対 path で実行する (cwd 非依存化)

- **背景**: `.rulesync/hooks.json` の command が `bash hooks/...` の cwd 相対だったため、エージェントが `cd` して session の cwd が変わると hook スクリプトを見つけられず発火に失敗する。hook スクリプト内部にも `templates/specs/...` 等の project root 相対参照がある。
- **判断**: 全 command を `cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" && <従来の相対 command>` に統一した。Claude Code は hook 実行時に `$CLAUDE_PROJECT_DIR` (プロジェクトルート) を提供するためこれを第一に使い、変数が無い provider では cwd の git root、git repo 外では現 cwd (従来挙動) に順にフォールバックする。
- **理由**: スクリプトの位置解決と内部の相対参照の両方が、command 側の 1 箇所の cd で同時に直る (各スクリプトへの root 解決コードの重複追加を避ける)。`$0` / `BASH_SOURCE` による root 解決は symlink 配布時に配布元へ寄る問題があるため採らない (参考 repo の hook 実装規約と同判断)。
- **今後**: 新しい hook を hooks.json に足すときは必ず同じ cd prefix を付ける。スクリプト側で `$0` から repo root を解決する実装は却下。`git rev-parse` フォールバックは cwd が別 repo のときその repo を root とみなす限界があるが、第一解決の `$CLAUDE_PROJECT_DIR` が効く Claude Code では発生しない。

## 2026-07-07 PR レビューコメントは統合レポート 1 本 + 対応記録の返信 1 本 / 外来語を平易な日本語に統一

- **背景**: 参考 repo (Fukuemon/skills) は pr-agent の MR レビューと「ディスポジション」(指摘への対応可否・理由の記録コメント) を運用している。本リポジトリの `multi-agent-review` に同等の PR コメント投稿を足すにあたり、コメントの粒度と用語が論点になった。
- **判断**: ① 投稿は統合レポート 1 本のコメント (マーカー `<!-- multi-agent-review -->` + 再実行時は既存コメントを更新) とし、指摘ごとの個別コメントはばら撒かない。指摘への対応は返信 1 本に「対応した / 対応しない (理由必須) / 後続対応 (行き先必須)」でまとめる。`high` 指摘の「対応しない」はユーザー判断必須。② 用語は styleguide-documents (曖昧さの排除) に従い、「ディスポジション」→「指摘への対応記録」、「還流」→「書き戻す / 書き戻し」に統一した。
- **理由**: 個別コメント方式は通知が荒れ、再実行のたびに重複が積もる。マーカー + 更新方式なら再実行しても PR 上のレビュー状態が 1 箇所に保たれる。用語は仲間内の外来語より、動作がそのまま読める日本語の方が消費 repo の初見者にも解釈の揺れがない。
- **今後**: 「指摘ごとに inline コメントを付けたい」提案は、GitHub の suggested changes 連携など具体的な利点が出てから再検討する (その場合も対応記録の一元化は維持)。skill / 文書に新しい概念を導入するときは、外来語のまま持ち込まず日本語の平易な表現に言い換える。

## 2026-07-07 レビュー観点の正本を spec-reviewer subagent に移す (skill は委譲と集約のみ)

- **背景**: `spec-review` skill が観点表を `references/review-rubric.md` に持ち、汎用 subagent (Plan / general-purpose) にファイルパスとして渡していた。参考 repo (Fukuemon/skills) は「観点の正本は subagent 定義に置き、skill 側で再記述しない」を著作原則とする。subagent 定義なら rulesync 経由で各 provider の agents ディレクトリに同形式で配布される。
- **判断**: 観点表を `.rulesync/subagents/spec-reviewer.md` (Read / Grep / Glob のみ・Write / Edit なし) に移し、`spec-review` skill は委譲と集約のみを担う。`references/review-rubric.md` は削除。subagent を起動できない環境では、汎用 read-only subagent に定義ファイルを Read させる fallback を skill に明記する。
- **理由**: 観点が skill references と subagent 定義に二重化する余地を最初から塞ぐ。評価専用 (書込ツールなし) の性質もツール宣言として定義側で機械的に表現できる。
- **今後**: レビュー観点の追加・変更は `spec-reviewer.md` のみを編集する。「skill 側にも観点の要約を置きたい」提案は二重化を招くため却下 (skill は subagent 名参照のみ)。

## 2026-07-07 重複しはじめた規範を contract に一本化 (用語規約 / 文書メタ情報の同期)

- **背景**: 「handoff 済み spec を『正本』と呼ばない」「本文更新時にメタ情報 (更新日 / ステータス / 変更履歴) も同期する」という 2 規範が、phase-sync / phase-track / review-rubric / completeness / structure の 5 ファイルに別文面で追記されていた。将来の規範変更時に 5 箇所の更新漏れで矛盾する。
- **判断**: 正本を `Spec Workflow Contract` (正本境界の「用語規約」/ 新設「文書メタ情報の同期」) に 1 回だけ書き、各ファイルは 1 行参照に畳んだ。あわせて Skill 共通契約に「同じ規範を複数ファイルに再掲しない。正本を 1 箇所に置き、他は 1 行で参照する」を追加。
- **理由**: 参考 repo の記載スタイル規範 (正本 1 箇所 + 1 行参照) に従う。rubric 側は「チェック観点」として規範を検証する記述は残してよいが、規範そのものの再定義は持たない。
- **今後**: 複数 skill にまたがる規範を足すときは、まず contract (`.rulesync/rules/CLAUDE.md`) に正本を置けないか検討する。同一規範の 2 箇所目の全文記載は却下。

## 2026-07-07 skill references は常時ロード rules ほどの圧縮を強制しない

- **背景**: 参考 repo は frontend rules を 3,418 行 → 451 行に圧縮した (常時ロードの rule は毎ターン token を消費するため)。本リポジトリの styleguide-documents references は 100〜220 行あり、同じ圧縮圧をかけるべきか論点になった。
- **判断**: skill の references はオンデマンドロード (該当 phase / トピックに到達したときのみ Read) のため、常時ロード rules の圧縮規範は適用しない。上限は Anthropic 公式ガイドの SKILL.md 500 行 (本リポジトリはより厳しく 200 行) と「100 行超の reference には冒頭に目次」のみ。
- **理由**: 参考 repo の圧縮判断の根拠は「常時ロード = 毎ターン課金」であり、オンデマンドの references には当てはまらない。公式ベストプラクティスも「参照ファイルは読まれるまで token を消費しない」ことを progressive disclosure の利点として明記している。
- **今後**: 「references も 150 行に分割しよう」という一律ルールの提案は却下。分割はトピックが混在して部分読みが起きるときのみ行う。

## 2026-07-07 生成物 4 系統をコミットし make check で drift を検査する (dist worktree symlink 方式は採らない)

- **背景**: 参考 repo は中央で rulesync 生成した `dist/<category>` を消費 repo に read-only symlink する方式 (generate-then-symlink) に収束した。本リポジトリも同方式に寄せるか論点になった。
- **判断**: 本リポジトリは `.rulesync/` を live symlink で配る現行方式 (link.sh・双方向編集) を維持し、生成物 (`AGENTS.md` / `CLAUDE.md` / `.agents/` / `.claude/` / `.codex/` / `.cursor/`) はコミットする。代わりに `make check` (再生成 → git diff 検査) を追加し、CI (GitHub Actions) で drift を硬いゲートにする。skill 契約の機械検査 (`scripts/check-skills.sh`) は高速なので lefthook pre-commit にも載せるが、生成物 drift 検査は npx / ネットワークを要するため CI のみとする。
- **理由**: 参考 repo の dist 方式は「消費側が rulesync を持たない」「Codex hooks の形式差」を中央で吸収するためのもの。本テンプレは消費 repo 側でも `rulesync generate` を回す設計 (README / link.sh) なので、中間 dist を持つ利点が薄い。drift の実害 (「古い設定が silent に配られる」) は check の機械化で塞がる。
- **今後**: 「dist/ を導入して worktree symlink にしよう」という提案は、消費 repo が rulesync を実行できない制約が実際に発生してから再検討する。`make check` を CI から外す提案は却下。

## 2026-07-07 skill description は日本語 third-person + トリガー語列挙に統一

- **背景**: description が英語 (11 skill) と日本語 (2 skill) で混在していた。参考 repo は日本語 + 発動トリガー語を引用符で列挙する形式で統一している。
- **判断**: 全 skill を日本語 third-person「何をする + いつ起動」+ トリガー語引用符列挙に統一し、Skill 共通契約にも明文化した。
- **理由**: リポジトリの一次言語 (docs / contract) が日本語であり、ユーザー発話も日本語が主。description は skill 選択のマッチング材料なので、発話言語と揃えてトリガー語を明示する方が発動が安定する。
- **今後**: 新規 skill の description は日本語で書く。英語へ戻す提案は、英語話者の消費 repo が実際に現れてから locale 分岐を検討する。
