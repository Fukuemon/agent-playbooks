# SDD Template

Spec Driven Development (SDD) のための **汎用 AI ワークフローテンプレート**。PRD / Design Doc / context library / spec を一貫した正本構造で管理し、AI エージェントが後続実装できる粒度の設計文書を作る。

設定は `.rulesync/` を単一情報源とし、`rulesync` で Cursor / Claude Code / Codex CLI 等の各 provider へ展開する。

## ドキュメント階層 (Why / What / How)

| 層                | 文書                                          | 役割                                               |
| ----------------- | --------------------------------------------- | -------------------------------------------------- |
| Why / What        | [PRD.md](PRD.md) (統合時は Design Doc に内包) | 誰のどの課題を、なぜ・何で解決するか               |
| How (全体像)      | [design/DesignDoc.md](design/DesignDoc.md)    | system landscape / モジュール責務 / 横断方針       |
| How (feature)     | [design/features/](design/features/)          | feature 単位の設計                                 |
| How (規約 / 契約) | [context/](context/)                          | 技術規約・codebase architecture・運用契約          |
| 固有値            | [context/project.yml](context/project.yml)    | repo / 命名 / コマンド / 対象ドメイン / トラッカー |
| 意思決定          | [adr/](adr/)                                  | 長期参照する技術選定・境界                         |
| 作業文書          | [specs/](specs/)                              | issue / 機能単位の要求・設計・テスト観点           |

操作契約の正本は [.rulesync/rules/CLAUDE.md](.rulesync/rules/CLAUDE.md) (生成元)。

## はじめかた (新規プロダクトへの適用)

1. **PRD / Design Doc を作る** — `design-doc` skill。要件規模から PRD の要否を判定し、分離モード (PRD.md + DesignDoc.md) か統合モード (DesignDoc に Why/What を内包) を選ぶ。
2. **context を初期化する** — `context-bootstrap` skill。Design Doc と短い対話から [context/project.yml](context/project.yml) と `context/*.md` を生成する。`<PLACEHOLDER>` を埋める。
3. **AI 設定を同期する** — `rulesync-sync` skill。`.rulesync/` から各 provider 設定 (`AGENTS.md` / `CLAUDE.md` / `.cursor/` / `.codex/`) を生成する。
4. **issue 駆動で進める** — `spec-*` skill 群 (intake → specify → clarify → design → sync → tasks → review)。`spec-lifecycle` が phase を orchestration する。

## 消費 repo へ接続する (共有プロセス層)

開発プロセスに関する資産は汎用なので、各プロダクト repo へ共有できる。配布形式は 2 層に分かれる:

- **ソース層 (`.rulesync/`) = live symlink**: skills / 操作契約 / subagents。どちらの repo で編集しても両方に反映される (「片方更新 → 両方更新」)。symlink は消費 clone の `.git/info/exclude` に登録され、commit 差分は出ない (per-clone)。
- **実行時参照される層 (`hooks/` / `scripts/generate.sh` 系 / `lefthook.yml`) = 実ファイルコピー**: commit 済みの `.claude/settings.json` 等が実行時に `hooks/...` を参照し、`make -f sdd-template.mk generate` が実行時に `scripts/generate.sh` (と `scripts/fix-*.sh`) を参照するため、clone しただけの環境 (CI / クラウドエージェント / テンプレ未 clone のマシン) でも実在する必要がある。消費 repo が commit して所有する。

```bash
# このテンプレ repo 上で実行
make link ARGS=/path/to/your-product-repo
# または: bash scripts/link.sh /path/to/your-product-repo
```

- 共有されない固有値 (消費 repo が所有): `context/` (`project.yml` 等) / `PRD.md` / `design/` / `specs/` / `adr/`
- `.template-version` に配布元テンプレの commit SHA が記録される (更新の追跡用)。

接続後、消費 repo 側で各 provider 設定を生成し、生成物・hooks を commit する:

```bash
cd /path/to/your-product-repo
make -f sdd-template.mk generate                                # rulesync + provider 別正規化
npx lefthook install                                             # git hooks の有効化
git add hooks scripts lefthook.yml sdd-template.mk .template-version AGENTS.md CLAUDE.md .agents .claude .codex .cursor .mcp.json
```

生成物・hooks・scripts/generate.sh 系を commit するのは、clone-and-go (CI / クラウドエージェント) でも
設定・hook・generate が効くようにするため。テンプレ側の更新は `link.sh` の再実行で取り込み、差分を commit する。

## closeout の自動化 (spec 残存の検査 + 削除 PR の自動起票)

spec は issue close 時に削除する契約 (`spec-lifecycle` の `references/closeout.md`) だが、手順だけでは実行が担保されない。2 段構えで塞ぐ。**自動では消さない** — 削除の前提「durable な設計成果が design / context / ADR へ sync 済みか」は機械判定できないため、判断は人に残し、toil (削除作業) だけを自動化する。

| 仕組み             | 実体                                                                             | 配布                                                                                                   |
| ------------------ | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| 残存検査           | `scripts/check-specs-residue.sh` → `make -f sdd-template.mk check-specs`         | 実ファイルコピー (`hooks/` / `generate.sh` と同じ列)                                                   |
| 削除 PR の自動起票 | `.github/workflows/spec-closeout.yml` (issue close をトリガに削除 PR を起票)     | **無ければコピー**。既存 workflow を上書きしない (更新は `templates/consumer/` と差分比較して取り込む) |
| 検査の CI 常設     | `.github/workflows/spec-residue.yml` (デフォルトブランチへの push + 毎週 + 手動) | 同上                                                                                                   |

検査は `context/project.yml` の `paths.spec_dir` と `gh` が解決する origin を使い、repo 名やコマンドを直書きしない。終了コードは `0` 残存なし / `1` 残存あり / `2` 検査不能 (gh の認証・権限・想定外の値) で、**`2` は合格ではない**。

自動起票を使う消費 repo 側の前提:

- Settings → Actions → General で **Workflow permissions = Read and write** と **Allow GitHub Actions to create and approve pull requests** を有効にする (後者が無いと `gh pr create` が失敗する)
- `issues` イベントの workflow は**デフォルトブランチ版が実行される**ため、workflow をマージするまで発火しない
- 起票された PR で CI を回したいなら (required check がある repo では必須)、secret `CLOSEOUT_PR_TOKEN` に PAT / GitHub App token を置く。既定の `github.token` による push / PR 作成は再帰実行防止で workflow を発火させないため、未設定だと起票された PR に CI が回らない
- `Closes #N` で issue を閉じる実装 PR に spec 削除を含めると、「issue は閉じたが spec は残っている」窓が生じない
- 検査 CI は **PR ゲートにしていない** — 別 PR で清算する運用だと上記の窓の間、無関係な PR が落ちるため。ゲートにするなら「issue を閉じる PR に削除を含める」運用を先に徹底する (`spec-residue.yml` 末尾のメモ)

## プロジェクト選択型 skill

言語・framework など、プロジェクトによって要否が分かれる skill は `.rulesync/skills/` に含めず、
リポジトリ直下の `skills/` で配布する。必要な消費 repo だけで次を実行する。

```bash
npx skills add Fukuemon/sdd-template --skill effective-go
```

`npx skills add` が生成する agent 別 skill は、その消費 repo 側で管理する。

固有値 (`context/project.yml` の repo / 命名 / コマンド / トラッカー等) は消費 repo 側で
実ファイルとして記入する。skill / 契約は抽象のまま `context/` を参照する。

## token 削減 (RTK — 任意)

エージェントが読む bash 出力を圧縮する CLI プロキシ [RTK](https://github.com/rtk-ai/rtk) を推奨する。**各開発者のマシン単位 (global) の設定**として入れる。repo 側の hook には登録していないため、未導入でも全 workflow は成立する。

```bash
brew install rtk
rtk init -g          # Claude Code / Copilot (--codex / --agent cursor もある)
rtk gain             # 削減量の確認
```

導入後は Bash tool の `git status` 等が `rtk git status` に書き換えられ、出力が圧縮されてから context に載る。詳細・注意点 (Read/Grep tool は通らない / 全文が必要な検証では素の命令を使う) は
[.rulesync/skills/dev-commands/references/rtk.md](.rulesync/skills/dev-commands/references/rtk.md)。repo 側の対応は 2 点:

- `.rulesync/permissions.json` は **読み取り系の `rtk` サブコマンドのみ allow** (書き込み系は素の命令と同じく都度承認)。ただし RTK の hook は書き換えたコマンドを `permissionDecision: "allow"` で返し**承認プロンプトを飛ばす**ため、承認ゲートは permissions ではなく hook で塞ぐ (実測は `references/rtk.md`)
- `hooks/protected-branch/pre_tool_use.py` は `rtk` 前置を剥がして判定するので、`rtk git commit` も protected branch でブロックされる

## 文書品質

すべての設計文書は `styleguide-documents` skill の 5 原則 (曖昧さ排除 / 意思決定理由 / AI 実装可能な粒度 / 可読構造 / 過剰装飾の回避) に従う。

## ディレクトリ

```text
.rulesync/   # AI 設定の単一情報源 (rules / skills / hooks / permissions / mcp)
skills/      # 言語・framework 固有の選択導入型 skill (`npx skills add` 用)
context/     # 技術規約・運用契約 + project.yml (固有値)
design/      # Design Doc (landscape) と feature 設計
templates/   # PRD / Design Doc / context / spec / feature / requirements / adr のテンプレート
adr/         # Architecture Decision Records
hooks/       # protected branch / 文書検証 / markdown 整形などの hook
```
