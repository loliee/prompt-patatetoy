PATH := $(PATH):$(HOME)/.local/bin:$(HOME)/bin:/usr/local/bin

.DEFAULT_GOAL := help

export PATH

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

shellcheck: ## Run shellcheck linter
	$(info --> Run shellcheck)
	@shellcheck -s bash $(PWD)/patatetoy_common.sh
	@shellcheck -s bash $(PWD)/patatetoy.sh

shfmt: ## Run shfmt linter
	$(info --> Run shfmt)
	@shfmt -i 2 -ci -d $(PWD)/patatetoy_common.sh
	@shfmt -i 2 -ci -d $(PWD)/patatetoy.sh

test: ## Run test suite
	$(info --> Test files)
	$(MAKE) shellcheck shfmt
