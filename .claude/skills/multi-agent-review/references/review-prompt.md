# Review Prompt

レビュープロンプトの組み立て方。全エージェントへ同一内容を渡す。

## 対象差分の取得

| 対象            | 取得コマンド                                                                                   |
| --------------- | ---------------------------------------------------------------------------------------------- |
| 現ブランチ diff | `git diff <base>...HEAD` (`<base>` は既定ブランチ。`context/project.md` の Naming/branch 参照) |
| PR              | `gh pr diff <番号>` (CLI は `context/project.md` の Issue Tracker)                             |
| spec            | 当該 `specs/<issue>/index.md` (+ 関連 design) の内容                                           |

- 差分が大きい場合はファイル単位に分割し、各エージェントのコンテキスト上限を超えないようにする (token 節約)。

## プロンプト雛形

```text
あなたはコードレビュアーです。以下の差分をレビューしてください。

## 観点 (rubric)
<code-review / spec-review から流用した観点を列挙>
- 正確性 / バグ
- 再利用・簡素化・効率
- 設計・上位文書との整合 (spec 対象時)

## 出力形式
各指摘を 1 行ずつ、次の形式で返してください:
- [重大度: high/medium/low] <file:line> — <指摘> / 根拠: <...> / 提案: <...>
指摘が無ければ "NO FINDINGS" とだけ返してください。

## 差分
<diff 本文>
```

## 注意

- rubric 観点は対象種別で切り替える (コード差分なら code-review、spec なら spec-review の rubric)。
- 出力形式を固定することで、後段の `finding-merge.md` がパースしやすくなる。
- プロンプト本文は `agent-orchestrate` が `prompt.txt` に固定し、全エージェントへ同一展開する。
