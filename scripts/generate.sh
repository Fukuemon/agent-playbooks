#!/usr/bin/env bash
# .rulesync/ から各 provider 設定を生成し、provider 別 normalizer を適用する。
# 唯一の生成シーケンス。Makefile / templates/consumer/sdd-template.mk /
# scripts/check-generated.sh はすべて本スクリプトを呼ぶ (手動列挙による同期漏れを防ぐ)。
# 冪等なので何度実行してもよい。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

npx rulesync@latest generate
bash "$ROOT/scripts/fix-cursor-cli.sh"
bash "$ROOT/scripts/fix-codex-config.sh"
bash "$ROOT/scripts/fix-claude-settings.sh"
