# GitHub Issue フォーマット

GitHub Issue のタイトル・本文フォーマット。

## Issue の種類

| type       | タイトル形式            | type ラベル     | 用途                           |
| ---------- | ----------------------- | --------------- | ------------------------------ |
| `feature`  | `✨ feature: <サマリ>`  | `type:feature`  | 新機能、利用者価値を増やす改善 |
| `bug`      | `🐛 bug: <サマリ>`      | `type:bug`      | 不具合修正                     |
| `research` | `🔎 research: <サマリ>` | `type:research` | 調査、技術検証、スパイク       |
| `task`     | `🛠 task: <サマリ>`     | `type:task`     | 実装や運用で実施すべき具体作業 |
| `chore`    | `🧹 chore: <サマリ>`    | `type:chore`    | 保守、設定変更、依存更新、雑務 |

## タイトル

```text
<絵文字> <type>: <サマリ>
```

- 日本語で簡潔に、末尾句点なし
- 50 文字以内を目安にする
- type は本文テンプレートと一致させる

## 本文テンプレート

- `feature`: [../assets/issue-feature-template.md](../assets/issue-feature-template.md)
- `bug`: [../assets/issue-bug-template.md](../assets/issue-bug-template.md)
- `research`: [../assets/issue-research-template.md](../assets/issue-research-template.md)
- `task`: [../assets/issue-task-template.md](../assets/issue-task-template.md)
- `chore`: [../assets/issue-chore-template.md](../assets/issue-chore-template.md)

### 節の規約 (必須 / 任意)

- 見出しは各テンプレの**日本語見出しをそのまま**使う。訳し替え・言い換え・新設をしない。1 つの issue 内で日英を混ぜない
- **任意節**は `補足` / `参考資料` / `依存関係` のみ。**該当する内容が無い場合のみ**節ごと削る
- それ以外の節は必須。書く内容が無い場合は削らず「なし」と理由を書く (空欄・空バレットのまま残さない)

## ラベル

ラベル体系の正本は **`context/project.yml` の `labels`**。本ファイルに固有値を直書きしない。起票時 (`gh issue create --label ...`) に最低限:

- `type:*` を 1 件 (上表の type ラベルと一致)
- 実装対象が定まるなら該当する `domain:*` (`context/project.yml` の `domains` に対応)
- SDD の設計フェーズなら `phase:design`、実装フェーズなら `phase:implementation`
- 複数 phase / spec にまたがる大きい要件 (親) には `epic`

ラベルが repo に未作成なら `gh label create` で先に作る (定義は `labels`)。

## メッセージ生成の原則

1. 実際の問題や要件を正確に把握してから書く
2. 曖昧な表現を避け、具体的な作業や確認条件を書く
3. 調査 issue では「何を判断できれば終わりか」を明示する
4. task や chore では、作業内容を検証可能な粒度に分解する
5. requirements / spec などの作業文書 (`specs/` 配下) の**全文を本文に貼らない**。本文は要約にとどめ、詳細は作業文書へリンクする (全文コピーは起票時点で凍結され、以後の更新と drift する)。skill からの起票 (`spec-requirement` 等) も本フォーマットに従う
