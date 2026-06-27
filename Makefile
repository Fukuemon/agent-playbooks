.PHONY: help link generate

help: ## このヘルプを表示
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ { printf "\033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

link: ## 消費 repo へ共有プロセス層を symlink する (ARGS=<consumer-repo-path>)
	@bash scripts/link.sh $(ARGS)

generate: ## .rulesync から各 provider 設定を生成し cursor cli.json を整形
	@npx rulesync@latest generate && bash scripts/fix-cursor-cli.sh
