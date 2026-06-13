# Project Profile

> 最終更新: YYYY-MM-DD

このプロダクト固有の値 (リポジトリ / 命名 / コマンド / 対象ドメイン / トラッカー / 正本パス) を集約する **唯一の正本**。`.rulesync/rules/CLAUDE.md` と `spec-*` / `dev-commands` 等の skill は、固有値をハードコードせず本ファイルを読む。

<!--
記入ガイド:
- 新規プロダクトでは `<...>` のプレースホルダをすべて埋める。
- DesignDoc から導ける値は context-bootstrap skill が下書きする。
- 値を変えたら先頭の「最終更新」を更新し、依存する context/*.md との整合を確認する。
-->

## Repository Map

- リポジトリ管理: `<ghq などのパス規約。例: $(ghq root)/<host>/<org>/<repo>>`
- app repo: `<path>`
- infra repo (別管理の場合): `<path / なければ「なし」>`

```text
<repo-root>/
├── <主要ディレクトリ構成をここに記述>
├── design/        # 全体像 (landscape) と feature 設計
├── context/       # 技術規約 / codebase architecture / 運用契約 (本ライブラリ)
└── specs/         # 機能単位の作業文書
```

## Naming Conventions

- パッケージ名: `<例: @<scope>/<module>>`
- コンポーネント / ファイル: `<例: PascalCase>`
- ブランチ: `<例: feature/<issue-id>>`

## Quick Commands

| やりたいこと     | コマンド |
| ---------------- | -------- |
| 開発起動         | `<cmd>`  |
| ビルド           | `<cmd>`  |
| Lint / typecheck | `<cmd>`  |
| Format (確認)    | `<cmd>`  |
| Unit test        | `<cmd>`  |
| E2E              | `<cmd>`  |
| 健全性検査       | `<cmd>`  |
| 依存追加         | `<cmd>`  |

## 対象ドメイン (spec「実装対象」テーブル用)

`<module-a>`, `<module-b>`, ...

## Label Policy

Issue / PR のラベル体系の **唯一の正本**。`workflow-git` skill はラベル付与時に本節を読む。命名は **名前空間付き** (`<axis>:<value>`) とし、軸ごとに色を揃える。

### 軸とラベル

| 軸         | ラベル                                                                     | 付与ルール                                                     | 色        |
| ---------- | -------------------------------------------------------------------------- | -------------------------------------------------------------- | --------- |
| `type:*`   | `type:feature` / `type:bug` / `type:research` / `type:task` / `type:chore` | **必須・1 件**。issue の種類 (issue-format と一致)             | `#1d76db` |
| `phase:*`  | `phase:design` / `phase:implementation`                                    | SDD ライフサイクル。設計 issue は `phase:design`               | `#5319e7` |
| `domain:*` | `<domain:module-a>` / `<domain:module-b>` / ... / `domain:core`            | **1 件以上**。上記「対象ドメイン」に対応。横断は `domain:core` | `#0e8a16` |
| (flag)     | `epic`                                                                     | 複数 phase / spec にまたがる大きい要件 (親)                    | `#fbca04` |

> `domain:*` は「対象ドメイン」節と一対一。ドメインを増やすときは両方を更新する。`type:*` は [workflow-git の issue-format](../.rulesync/skills/workflow-git/references/issue-format.md) の type と一致させる。

### 付与の最低ライン

- すべての issue に `type:*` を 1 件付ける。
- 実装対象が定まる issue には該当する `domain:*` を付ける。
- SDD の設計フェーズ issue には `phase:design`、実装フェーズには `phase:implementation`。
- 1 つの要件が複数 phase / spec に展開される親 issue には `epic` を付ける。

## Issue Tracker

- Tracker: `<GitHub / GitLab / Redmine / Jira / ...>`
- CLI: `<gh / glab / ...>`
- Repo: `<org/repo or project path>`
- Branch pattern: `<feature/<issue-id>>`

## Source of Truth (正本ドキュメントのパス契約)

`spec-*` skill が参照するパス。`Spec Workflow Contract` はこの表を読む。

- PRD: `PRD.md` (統合モードでは `design/DesignDoc.md` の Why/What 節)
- Design Doc (landscape): `design/DesignDoc.md`
- feature doc dir: `design/features/<feature>/`
- feature doc: `design/features/<feature>/DesignDoc_<feature>.md`
- context library: `context/<topic>.md`
- ADR: `adr/`
- spec dir: `specs/<issue-id>-<slug>/`
- spec body: `specs/<issue-id>-<slug>/index.md`
- spec prompts: `specs/<issue-id>-<slug>/prompts/`
- spec requirements (任意): `specs/<issue-id>-<slug>/requirements.md`
- spec review report (任意): `specs/<issue-id>-<slug>/review.md`

## Templates

- PRD: `templates/prd/template.md`
- Design Doc: `templates/design-doc/template.md`
- context: `templates/context/<topic>.md`
- spec core: `templates/specs/template.md`
- spec appendices: `templates/specs/appendices/<topic>.md`
- feature doc: `templates/features/template.md`
- requirements: `templates/requirements/template.md`
- adr: `templates/adr/template.md`

## Decision Priority

迷ったときの判断優先度 (プロダクトに合わせて並べ替える):

1. `<例: パフォーマンス>`
2. `<例: 一貫性>`
3. `<例: 開発体験>`
4. `<例: 将来拡張性>`

技術選定の根拠は [Design Doc](../design/DesignDoc.md) と [ADR](../adr/)。
