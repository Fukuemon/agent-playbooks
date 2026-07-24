.PHONY: help link generate check check-skills check-generated

help: ## このヘルプを表示
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ { printf "\033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

link: ## 消費 repo へ共有プロセス層を symlink する (ARGS=<consumer-repo-path>)
	@bash scripts/link.sh $(ARGS)

generate: ## .rulesync から各 provider 設定を生成し provider 別の差分を整形
	@bash scripts/generate.sh

check: check-skills check-generated ## skill 契約 + 生成物 drift をまとめて検査 (CI と同じ)

check-skills: ## Skill 共通契約 (行数 / 必須セクション / frontmatter) を検査
	@bash scripts/check-skills.sh

check-generated: ## 生成物が .rulesync と同期しているか検査 (再生成して diff、npx 必要)
	@bash scripts/check-generated.sh
