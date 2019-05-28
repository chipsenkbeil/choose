# Prefix to installing manual pages
BASEDIR ?= /usr/local/share/man

# Specify targets that aren't actually physical files to create
.PHONY: clean build install uninstall help

all: build ## [DEFAULT] Build project

help: ## Display help information
	@printf 'usage: make [target] ...\n\ntargets:\n'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

build: ## Builds program
	@esy

run: ## Executes program
	@esy x Choose

install: ## Copy binaries to $BASEDIR

uninstall: ## Remove binaries from $BASEDIR

clean: ## Remove all generated binaries
	@rm -rf _build/
