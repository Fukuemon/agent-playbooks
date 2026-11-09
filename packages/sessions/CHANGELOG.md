# Changelog

## 0.1.0 (2026-11-09)


### ⚠ BREAKING CHANGES

* **sessions:** autonomous-run、pause-safely、session-pickup、delegate-work、coordinate-workers は、パッケージ sessions のスキル run-session から選ぶ。

### Features

* **sessions:** エビデンスの確認の待ちで止まらず、未確認の PR をマージしない [#67](https://github.com/Fukuemon/agent-playbooks/issues/67) ([59c1bca](https://github.com/Fukuemon/agent-playbooks/commit/59c1bca2b2267051472a8ed6564f765b69a52220))
* **sessions:** 引き継ぎのメモを主題のディレクトリに置き、動いているものとコンテキストの知らせの入り口を足す [#58](https://github.com/Fukuemon/agent-playbooks/issues/58) ([b673686](https://github.com/Fukuemon/agent-playbooks/commit/b6736861eb41ed3509acef2cdfd0d7c17c054b18))
* **sessions:** 長い作業と委譲の playbook をパッケージ sessions に移す [#56](https://github.com/Fukuemon/agent-playbooks/issues/56) ([0cb7334](https://github.com/Fukuemon/agent-playbooks/commit/0cb7334061a8272ae423cca34228678e0eddf87c))
* **sessions:** 長い作業と配る作業を判断の 3 段に合わせ、起動の時点から監視する [#58](https://github.com/Fukuemon/agent-playbooks/issues/58) ([cd24b10](https://github.com/Fukuemon/agent-playbooks/commit/cd24b10aaee130fd5a6d0f322b0220909146d4ca))


### Bug Fixes

* **sessions:** run-session が最初に run-playbook の共通の規則を読むようにする [#56](https://github.com/Fukuemon/agent-playbooks/issues/56) ([c7db016](https://github.com/Fukuemon/agent-playbooks/commit/c7db0164f44351c35f32c0e0d523a77666005e5b))
* **sessions:** エビデンスの段を飛ばした PR をマージの待ちから外す [#67](https://github.com/Fukuemon/agent-playbooks/issues/67) ([540ddbb](https://github.com/Fukuemon/agent-playbooks/commit/540ddbb7cab83f66b11e32ec29be6123ef759a7c))
* **sessions:** コンテキストで止まったワーカーの作業を新しいワーカーに渡す [#58](https://github.com/Fukuemon/agent-playbooks/issues/58) ([169105a](https://github.com/Fukuemon/agent-playbooks/commit/169105ad810c3ab4f7b8e752d0ea72d3fc8a06f6))
* **sessions:** 次のセッションの起動をコンテキストで止まったときに限る [#58](https://github.com/Fukuemon/agent-playbooks/issues/58) ([65d54f7](https://github.com/Fukuemon/agent-playbooks/commit/65d54f75ccb9a9a096b01ac4fd78cb7f4c4b2f8d))
