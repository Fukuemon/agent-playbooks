# Closeout: issue close 後に spec を削除する

spec は **issue 単位の作業文書** であり、issue が閉じたら役目を終える。残しておくと design 側に
spec への索引が積もって認知負荷が上がり、現行実装と食い違った古い spec がドリフトの温床になる。
durable な情報は sync で design / ADR / context に救出済みであることを確認した上で、spec dir を削除する。
削除後も経緯は issue / PR / git history (`git log --all -- 'specs/<issue-id>-*'`) で追える。

## 実行タイミング

実装 PR の merge で issue が close した後 (`workflow-git` の PR workflow から案内される)。

## 前提条件 (すべて満たすまで削除しない)

- [ ] sync 完了: spec の `## 上位資料からの変更点` に未反映の「変更提案」行がない
- [ ] 対象 issue が closed (実装 PR merge 済み)
- [ ] この spec を変更元とする派生 issue (`quality:*`) が open で残っていない (例外は下記)
- [ ] `prompts/` の実装作業がすべて完了している (未実行 prompt が残っていない)

### 例外: open な派生 issue が残っていても削除してよい場合

派生 issue が **spec の記述に依存していない** (本文がコード path / feature doc / ADR のみを参照し、
spec へのリンク・引用を持たない) ことを全件確認できたなら、open のままでも削除してよい。

- 依存している派生 issue がある場合は、依存箇所を durable 文書 (feature doc / context / ADR)
  へ移すか issue 本文へ転記してから削除する
- 例外を適用したときは、確認した派生 issue 番号と判断根拠を削除 commit / PR に記録する

## 手順

1. **最終刈り取り** (取りこぼしの最後の検出点):
   - `## 解決済みの論点` を全行走査し、各行に「反映先 (design / ADR) または spec で閉じる」の
     判定が付いているか確認する。**選択肢を比較して決めた判断で ADR 未起票のものがあれば、
     削除前に ADR に起こす** (spec 削除後、「なぜこうしたか」を再現できる場所は ADR だけになる)
   - 横断的な知見 (ハマりどころ / 暗黙の仕様) が残っていれば `context-harvest` で書き戻す
2. **ADR の反映リストの消し込み**:
   - この issue で起票・更新した ADR の `## 実装・運用への反映` を 1 項目ずつ確認し、
     **未実施のものが無いことを確かめる**。残っていれば実施するか、別 issue に起こす
   - ADR が自ら書いた反映作業は、誰も実行しないまま残りやすい (実例: 可視化スコープを
     外す ADR が「feature doc の該当節も削除する」と書きながら数週間放置され、
     コードから定数を消した後も文書だけ食い違っていた)
   - 実施済みなら該当行に反映先の PR 番号を添える

3. **参照の後始末**:
   - 読み取り索引が spec への参照を持つ場合、`source_refs:` から当該 spec のパスを除去し
     ADR / feature doc に差し替える (`read:` は design 側を指しているはずなので通常変更不要)。
     索引の場所・更新手段は `spec-contract.md` の「読み取り索引の解決」に従う
   - feature doc / ADR に spec への決定経緯リンクがあれば、issue へのリンクに差し替える
4. **削除の承認**: 削除対象・刈り取り結果・参照差し替えを提示し、承認を取る (contract の「承認の取り方」)
5. **削除と commit**: `git rm -r specs/<issue-id>-<slug>/` し、削除 commit のメッセージに
   issue 番号を含める (例: `chore(spec): closeout #<N> — durable 成果は <反映先> へ反映済み`)
6. **残存検査**: 残存検査を実行し、**残存ゼロを確認する** (手順を踏んだつもりで消し漏れる事故を塞ぐ最後のゲート)
   - 消費 repo: `bash scripts/check-specs-residue.sh` (link.sh が初期値として置く。以後は消費 repo が所有)
   - プロジェクトが独自の入口を持つ場合は `context/project.yml` の `commands` から解決する
   - 終了コード: `0` 残存なし / `1` 残存あり (closeout 未実施) / `2` 検査不能 (gh の認証・権限・想定外の値)。
     **`2` を合格として扱わない** — 検査できていないだけで、残存の有無は不明

## 実装 PR に削除を含めるか、別 PR にするか

`Closes #<N>` で issue を閉じる **実装 PR に spec 削除を含める**のが既定。close 時点で spec が無くなるため、
「issue は閉じたが spec は残っている」窓が生じない。

別 PR にする場合は、その窓の間だけ残存検査が `1` を返す。検査を CI の必須チェックにしているなら、
先に削除 PR をマージするか、window の扱いを決めてから分ける。

残存検査は消費 repo の CI (`.github/workflows/spec-residue.yml` — デフォルトブランチへの push + 毎週 + 手動)
にも載っている。PR ゲートではないため、検出は「マージ後に気付く」経路になる。手元で手順 5 を回すのが一次防御。

## 自動起票 workflow を使う場合

消費 repo に `.github/workflows/spec-closeout.yml` (テンプレ配布分) がある場合、issue の close を
トリガに **spec を削除する PR が自動起票される**。bot は削除せず提案するだけで、削除の可否は
その PR をマージするかどうかで決まる。

- 前提条件の確認・最終刈り取り・参照の後始末 (上記手順 1〜2) は **人が行う**。自動起票された PR の
  チェックリストがその確認項目になる
- 未反映の durable 成果が見つかったら PR をマージせず、先に sync してから再度 closeout する
- spec を残す判断をしたら PR を close し、**残す理由を issue にコメントする** (残存検査は検出し続ける)
- workflow が発火しない / 障害時は `workflow_dispatch` で issue 番号を指定して手動実行できる

## 停止条件

- 前提条件のいずれかが未達 (特に sync 未完 — 先に sync phase を実行する)
- 最終刈り取りで ADR 未起票の意思決定が見つかった (ADR 化してから再開する)
- 削除の承認が得られていない
- 参照の差し替え先 (ADR / feature doc) が存在しない — 反映漏れの兆候。sync に戻る
- 残存検査が `2` (検査不能) を返した — gh の認証・権限を直してから再実行する (合格扱いにしない)
