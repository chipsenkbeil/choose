# Prefix to installing manual pages
BASEDIR ?= /usr/local/share/man

# Specify targets that aren't actually physical files to create
.PHONY: clean build install uninstall

# [DEFAULT] Build project
all: build

build:
	@esy

run:
	@esy x Choose

# Copy binaries to $BASEDIR
install:

# Remove binaries from $BASEDIR
uninstall:

# Remove all generated binaries
clean:
	@rm -rf _build/
