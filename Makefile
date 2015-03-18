VERSION = $(shell defaults read `pwd`/Info CFBundleVersion)
APPFILE = choose
TGZFILE = choose-$(VERSION).tgz
ZIPFILE = choose-$(VERSION).zip

release: $(TGZFILE) $(ZIPFILE)

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

.PHONY: release clean
