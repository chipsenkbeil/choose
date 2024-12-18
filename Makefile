.PHONY: docs install-docs uninstall-docs help
VERSION = $(shell defaults read `pwd`/Info CFBundleVersion)
APPFILE = choose
TGZFILE = choose-$(VERSION).tgz
ZIPFILE = choose-$(VERSION).zip

release: $(APPFILE) ## Build release files

help: ## Display help information
	@printf 'usage: make [target] ...\n\ntargets:\n'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

package: $(TGZFILE) $(ZIPFILE) ## Build packages

docs: ## Build documentation
	@$(MAKE) -C docs

install-docs: ## Install documentation
	@$(MAKE) -C docs install

uninstall-docs: ## Uninstall documentation
	@$(MAKE) -C docs uninstall

clean: ## Remove generated files, packages, and documentation
	rm -rf $(APPFILE) $(APPFILE)-x86_64 $(APPFILE)-arm64 $(TGZFILE) $(ZIPFILE)
	@$(MAKE) -C docs clean

###############################################################################
# INTERNAL
###############################################################################

# Build a universal binary
$(APPFILE): $(APPFILE)-x86_64 $(APPFILE)-arm64
	lipo -create -output $@ $^

# Explicitly build an x86_64 version of choose
$(APPFILE)-x86_64: SDAppDelegate.m choose.xcodeproj
	rm -rf $@
	xcodebuild \
		-arch x86_64 \
		-configuration Release \
		clean build > /dev/null
	cp -R build/Release/choose $@

# Explicitly build an arm64 version of choose
$(APPFILE)-arm64: SDAppDelegate.m choose.xcodeproj
	rm -rf $@
	xcodebuild \
		-arch arm64 \
		-configuration Release \
		clean build > /dev/null
	cp -R build/Release/choose $@

# Build a tar.gz containing the binary
$(TGZFILE): $(APPFILE)
	tar -czf $@ $<

# Build a zip containing the binary
$(ZIPFILE): $(APPFILE)
	zip -qr $@ $<

