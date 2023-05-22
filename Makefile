.PHONY: help
help: ## Shows the Makefile targets
	@printf "\033[33mUsage:\033[0m\n  make [target] [arg=\"val\"...]\n\n\033[33mTargets:\033[0m\n"
	@grep -E '^[-a-zA-Z0-9_\.\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/\Makefile://g' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: dev
dev: ## Run project locally during development
	go run src/main.go

.PHONY: test
test: ## Run unit test project locally during development
	go run src/main.go

.PHONY: fmt
fmt: ## Format the Go code to keep it up to date with standards
	gofmt -w src
