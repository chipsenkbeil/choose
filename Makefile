.PHONY: docs install-docs uninstall-docs clean-docs help

help: ## Display help information
	@printf 'usage: make [target] ...\n\ntargets:\n'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

###############################################################################
# SOURCE PROGRAM
###############################################################################

build: ## Build source program
	@$(MAKE) -C Choose build

install: ## Installs source program
	@$(MAKE) -C Choose install

uninstall: ## Uninstalls source program
	@$(MAKE) -C Choose uninstall

run: ## Runs source program
	@$(MAKE) -C Choose run

###############################################################################
# DOCUMENTATION
###############################################################################

docs: ## Build documentation
	@$(MAKE) -C docs

install-docs: ## Install documentation
	@$(MAKE) -C docs install

uninstall-docs: ## Uninstall documentation
	@$(MAKE) -C docs uninstall

clean-docs: ## Removes built documentation
	@$(MAKE) -C docs clean
