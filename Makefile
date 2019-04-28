.PHONY: docs install-docs uninstall-docs clean-docs help

help: ## Display help information
	@printf 'usage: make [target] ...\n\ntargets:\n'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

docs: ## Build documentation
	@$(MAKE) -C docs

install-docs: ## Install documentation
	@$(MAKE) -C docs install

uninstall-docs: ## Uninstall documentation
	@$(MAKE) -C docs uninstall

clean-docs: ## Removes built documentation
	@$(MAKE) -C docs clean
