# Changelog

## [0.3.1](https://github.com/Fukuemon/agent-playbooks/compare/playbooks-v0.3.0...playbooks-v0.3.1) (2026-11-09)


### Bug Fixes

* **playbooks:** feature の spec を docs.spec の置き場に作る [#71](https://github.com/Fukuemon/agent-playbooks/issues/71) ([3f88a6f](https://github.com/Fukuemon/agent-playbooks/commit/3f88a6f3dc0bee561bdd7e68b873424220c0541f))

## [0.3.0](https://github.com/Fukuemon/agent-playbooks/compare/playbooks-v0.2.3...playbooks-v0.3.0) (2026-11-09)


### ⚠ BREAKING CHANGES

* **review:** スキル review-changes は review-by-viewpoints になり、パッケージ review に移った。
* **sessions:** autonomous-run、pause-safely、session-pickup、delegate-work、coordinate-workers は、パッケージ sessions のスキル run-session から選ぶ。

### Features

* **playbooks:** requirements で種別を選んでタスクに分け、種別から playbook を選ぶ [#63](https://github.com/Fukuemon/agent-playbooks/issues/63) ([cbbd1f1](https://github.com/Fukuemon/agent-playbooks/commit/cbbd1f1e7b15c5c610c5ec3ac0492749a1d6410c))
* **playbooks:** run-playbook に判断の 3 段と論点の尋ね方を入れ、場面で読む規則を rules/ に移す [#58](https://github.com/Fukuemon/agent-playbooks/issues/58) ([6d0737f](https://github.com/Fukuemon/agent-playbooks/commit/6d0737f31d2e892574f4730488b51376340e512e))
* **playbooks:** verification-setup を e2e と evidence の context に寄せる [#65](https://github.com/Fukuemon/agent-playbooks/issues/65) ([4c126c8](https://github.com/Fukuemon/agent-playbooks/commit/4c126c83353260073f51bd79e5c568e6ac2fd2fb))
* **playbooks:** 受け入れの検証、デザインシステム、画面仕様書の playbook を足す [#61](https://github.com/Fukuemon/agent-playbooks/issues/61) ([6af51db](https://github.com/Fukuemon/agent-playbooks/commit/6af51db1c2687bf48942a746fbda1f122728b90f))
* **playbooks:** 機能の PR にエビデンスを載せ、製品のパッケージの段を足す [#67](https://github.com/Fukuemon/agent-playbooks/issues/67) ([01ea821](https://github.com/Fukuemon/agent-playbooks/commit/01ea82163b65004cf3d444a2107099b145a2307a))
* **review:** レビューのスキルを review-by-viewpoints に改名し、パッケージ review に移す [#56](https://github.com/Fukuemon/agent-playbooks/issues/56) ([323303b](https://github.com/Fukuemon/agent-playbooks/commit/323303b548cabcd2b35c153f16188b0f4ef31e66))
* **sessions:** 長い作業と委譲の playbook をパッケージ sessions に移す [#56](https://github.com/Fukuemon/agent-playbooks/issues/56) ([0cb7334](https://github.com/Fukuemon/agent-playbooks/commit/0cb7334061a8272ae423cca34228678e0eddf87c))


### Bug Fixes

* **playbooks:** verification の段を飛ばしたときの終え方を書く [#61](https://github.com/Fukuemon/agent-playbooks/issues/61) ([695ab6f](https://github.com/Fukuemon/agent-playbooks/commit/695ab6f311b9df392c469924d807f1a795893f09))
* **playbooks:** 起票した要求の続きと、種別が無いときの分解の道を書く [#63](https://github.com/Fukuemon/agent-playbooks/issues/63) ([33e2e42](https://github.com/Fukuemon/agent-playbooks/commit/33e2e4278c7fc6e96c91dd1be87f1bd5196120f8))
* **sessions:** エビデンスの段を飛ばした PR をマージの待ちから外す [#67](https://github.com/Fukuemon/agent-playbooks/issues/67) ([540ddbb](https://github.com/Fukuemon/agent-playbooks/commit/540ddbb7cab83f66b11e32ec29be6123ef759a7c))
