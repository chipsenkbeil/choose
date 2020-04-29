.PHONY: docs install-docs uninstall-docs help

help: ## Display help information
	@printf 'usage: make [target] ...\n\ntargets:\n'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

build-debug: ## Build debug version of choose
	@CXXFLAGS+=-stdlib=libc++ cargo build

install-debug: ## Locally install the debug version of choose
	@CXXFLAGS+=-stdlib=libc++ cargo install --debug --path .

build: ## Build release version of choose
	@CXXFLAGS+=-stdlib=libc++ cargo build --release

install: ## Locally install the release version of choose
	@CXXFLAGS+=-stdlib=libc++ cargo install --path .

docs: ## Build documentation
	@$(MAKE) -C docs

install-docs: ## Install documentation
	@$(MAKE) -C docs install

uninstall-docs: ## Uninstall documentation
	@$(MAKE) -C docs uninstall
