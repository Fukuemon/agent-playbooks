# ブランチ命名規則

## フォーマット

```text
<prefix>/<チケット番号>
```

**パターン**: `^(feature|research|fix|refactor)/[0-9]+$`

## Prefix 一覧

| Prefix     | 用途                   |
| ---------- | ---------------------- |
| `feature`  | 新機能追加             |
| `research` | 調査、設計、検証       |
| `fix`      | 不具合修正             |
| `refactor` | 振る舞いを変えない整理 |

## 例

```text
feature/23426
research/23480
fix/23500
refactor/23512
```

## ブランチ戦略

固有値は `context/project.yml` の `naming` を読む。直書きしない。

- 統合ブランチは `naming.base_branch` (未定義なら repo の default branch を実測して確認する)
- 作業ブランチ (`feature/*` / `research/*` / `fix/*` / `refactor/*`) は `base_branch` から切り、作業後は `base_branch` へ戻す
- リリース先が分かれる運用 (Git Flow 等) は `naming.release_branch` に持つ。trunk based なら `null`

## チケット番号の抽出

ブランチ名からチケット番号を抽出する場合:

```bash
git branch --show-current | grep -oE '[0-9]+$'
```
