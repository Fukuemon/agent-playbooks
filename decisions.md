# Decisions — skill / rule 著作の判断記録

skill / rule / subagent を **どう作るか** の非自明な判断と「今後こうする」を残す。背景を知らない提案・issue で逆戻しされるのを防ぐのが目的。

**ここに書くもの**: 再学習コストが高く、diff では追えない割り切り (token コスト・ツール制約・スコープの線引き)。
**ここに書かないもの**: プロダクトの技術判断は [adr/](adr/) へ。skill 連鎖の構造は [architecture.md](architecture.md) へ。個々の変更履歴は git log で追う。

書式は 1 判断 1 セクション、**新しいものを上に**積む。各セクションは `背景 / 判断 / 理由 / 今後` の 4 項目。`今後` に「今後こういう提案は却下 / こう作る」を必ず書く。

---

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
