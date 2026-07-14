.PHONY: generate

generate: ## rulesync 生成と provider 別の正規化をまとめて実行
	@npx rulesync@latest generate \
		&& bash scripts/fix-cursor-cli.sh \
		&& bash scripts/fix-codex-config.sh \
		&& bash scripts/fix-claude-settings.sh
