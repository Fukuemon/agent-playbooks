.PHONY: help link sync generate dist check check-skills check-links check-dist

help: ## このヘルプを表示
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ { printf "\033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

link: ## 消費 repo へ共有プロセス層を symlink する (ARGS=<consumer-repo-path>)
	@bash scripts/link.sh $(ARGS)

sync: ## 配布 worktree (.wt/dist) を origin/main へ同期 (link 済み全 repo が更新される)
	@bash scripts/sync-dist.sh

generate: ## .rulesync から各 provider 設定を生成し provider 別の差分を整形
	@bash scripts/generate.sh

dist: ## .rulesync から dist/ を再生成する (消費 repo の symlink 先)
	@bash scripts/build-dist.sh

check: check-skills check-links check-dist ## skill 契約 + リンク + 生成物 / dist の drift を検査 (CI と同じ)

check-skills: ## Skill 共通契約 (行数 / 必須セクション / frontmatter) を検査
	@bash scripts/check-skills.sh

check-links: ## markdown 相対リンク (skill 外参照の禁止 / 参照先の実在) を検査
	@python3 scripts/check-links.py

check-dist: ## 生成物と dist/ が .rulesync と同期しているか検査 (npx 必要)
	@bash scripts/check-dist.sh
