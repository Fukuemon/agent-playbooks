# Changelog

## [0.2.2](https://github.com/Fukuemon/agent-playbooks/compare/v0.2.1...v0.2.2) (2026-10-23)


### Bug Fixes

* **playbooks:** 事前の権限と待ちの記録の食い違いを直し、マージの語をそろえる [#38](https://github.com/Fukuemon/agent-playbooks/issues/38) ([a98d0cc](https://github.com/Fukuemon/agent-playbooks/commit/a98d0ccdaa6796f35776e1d39e0f3e10e85ca8b3))

## [0.2.1](https://github.com/Fukuemon/agent-playbooks/compare/v0.2.0...v0.2.1) (2026-10-23)


### Features

* **playbooks:** 事前の権限で止まる場面を外し、再開のメモと判断の記録を引き継ぎのメモにまとめる [#34](https://github.com/Fukuemon/agent-playbooks/issues/34) ([57485c9](https://github.com/Fukuemon/agent-playbooks/commit/57485c952c345b7575118403eae2e464f6ec646c))
* **playbooks:** 作業を渡す playbook と配る playbook、待ちの上限の principle を足す [#34](https://github.com/Fukuemon/agent-playbooks/issues/34) ([d9850b0](https://github.com/Fukuemon/agent-playbooks/commit/d9850b0832ea42d7b6bfae25cee8083b57a08a4a))


### Bug Fixes

* **playbooks:** ワーカーへの指示に、写した委任と親の引き継ぎのメモの場所を持たせる [#34](https://github.com/Fukuemon/agent-playbooks/issues/34) ([f0da37b](https://github.com/Fukuemon/agent-playbooks/commit/f0da37ba792db8da2d8634b292f4ded8b542f298))

## [0.2.0](https://github.com/Fukuemon/agent-playbooks/compare/v0.1.0...v0.2.0) (2026-10-12)


### ⚠ BREAKING CHANGES

* **playbooks:** スキル playbook は run-playbook に、principle-* の 4 つのスキルは run-playbook の参照ファイルに変わった。/playbook の代わりに /run-playbook で呼ぶ。

### Features

* **playbooks:** スキル playbook を run-playbook に改め、playbook を足す ([0a0a25c](https://github.com/Fukuemon/agent-playbooks/commit/0a0a25c25f3f9fb1a2d82753664e5e2ae1d169a6))
* **playbooks:** 検証、学びの書き戻し、長い作業の playbook を足す ([b479a29](https://github.com/Fukuemon/agent-playbooks/commit/b479a29d0ce286537191b192996f58747543010c))


### Bug Fixes

* **playbooks:** pause-safely が止まる場面と中断のコミットの形を直す ([43c3599](https://github.com/Fukuemon/agent-playbooks/commit/43c3599c0700110af7745221dbae65574083c5e9))
* **playbooks:** PR を Draft で作るかを CONTRIBUTING.md に従わせる ([f6c64c3](https://github.com/Fukuemon/agent-playbooks/commit/f6c64c36defddaf622b01277cbfe05a5aa70776c))
* **playbooks:** レビューの subagent を観点と報告の形に絞る ([f69da2b](https://github.com/Fukuemon/agent-playbooks/commit/f69da2b62de66a5051953d75a7c3e0bd95300fc1))
* **playbooks:** 離れている間の作業を autonomous-run に振り分ける ([57fcc73](https://github.com/Fukuemon/agent-playbooks/commit/57fcc730ee141a91566958e87ce3574a6d3fcdbc))
