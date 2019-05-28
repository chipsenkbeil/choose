.PHONY: docs install-docs uninstall-docs help
VERSION = $(shell defaults read `pwd`/Info CFBundleVersion)
APPFILE = choose
TGZFILE = choose-$(VERSION).tgz
ZIPFILE = choose-$(VERSION).zip

release: $(TGZFILE) $(ZIPFILE) ## Build release files

help: ## Display help information
	@printf 'usage: make [target] ...\n\ntargets:\n'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

docs: ## Build documentation
	@$(MAKE) -C docs

install-docs: ## Install documentation
	@$(MAKE) -C docs install

uninstall-docs: ## Uninstall documentation
	@$(MAKE) -C docs uninstall

$(APPFILE): SDAppDelegate.m choose.xcodeproj
	rm -rf $@
	xcodebuild clean build > /dev/null
	cp -R build/Release/choose $@

$(TGZFILE): $(APPFILE)
	tar -czf $@ $<

$(ZIPFILE): $(APPFILE)
	zip -qr $@ $<

clean: ## Remove generated files and documentation
	rm -rf $(APPFILE) $(TGZFILE) $(ZIPFILE)
	@$(MAKE) -C docs clean

.PHONY: release clean
