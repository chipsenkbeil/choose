.PHONY: docs install-docs uninstall-docs
VERSION = $(shell defaults read `pwd`/Info CFBundleVersion)
APPFILE = choose
TGZFILE = choose-$(VERSION).tgz
ZIPFILE = choose-$(VERSION).zip

release: $(TGZFILE) $(ZIPFILE)

docs:
	@$(MAKE) -C docs

install-docs:
	@$(MAKE) -C docs install

uninstall-docs:
	@$(MAKE) -C docs uninstall

$(APPFILE): SDAppDelegate.m choose.xcodeproj
	rm -rf $@
	xcodebuild clean build > /dev/null
	cp -R build/Release/choose $@

$(TGZFILE): $(APPFILE)
	tar -czf $@ $<

$(ZIPFILE): $(APPFILE)
	zip -qr $@ $<

clean:
	rm -rf $(APPFILE) $(TGZFILE) $(ZIPFILE)
	@$(MAKE) -C docs clean

.PHONY: release clean
