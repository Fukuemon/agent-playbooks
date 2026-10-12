# Changelog

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
