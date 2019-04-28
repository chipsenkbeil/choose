# Prefix to installing manual pages
BASEDIR ?= /usr/local/share/man

# Manual pages to build (and pseudo targets to install/uninstall)
MANPAGES = choose.1
INSTALL_TARGETS = $(foreach page,$(MANPAGES),$(page).install)
UNINSTALL_TARGETS = $(foreach page,$(MANPAGES),$(page).uninstall)

# Specify targets that aren't actually physical files to create
.PHONY: clean install uninstall $(INSTALL_TARGETS) $(UNINSTALL_TARGETS)

# Function to use to convert choose.1 into <BASE DIR>/man1
F_OUTDIR = $(BASEDIR)/man$(subst .,,$(suffix $1))

# [DEFAULT] Build all manpages
all: $(MANPAGES)

# Copy all manpages to $BASEDIR
install: $(INSTALL_TARGETS)

# Remove all manpages from $BASEDIR
uninstall: $(UNINSTALL_TARGETS)

# Copy specific manpage denoted by <MANPAGE>.install to $BASEDIR
$(INSTALL_TARGETS):%:$(MANPAGES)
	$(info Installing $(basename $@))
	@mkdir -p $(call F_OUTDIR,$(basename $@))
	@cp $(basename $@) $(call F_OUTDIR,$(basename $@))/$(basename $@)

# Remove specific manpage denoted by <MANPAGE>.install from $BASEDIR
$(UNINSTALL_TARGETS):%:
	$(info Uninstalling $(basename $@))
	@rm -f $(call F_OUTDIR,$(basename $@))/$(basename $@)

# Build specific manpage from <MANPAGE>.md to <MANPAGE>
$(MANPAGES):%:%.md
	$(info Building $@ from $<)
	@pandoc -s -f markdown -t man $< | dos2unix > $@

# Remove all generated manpages
clean:
	@rm -f $(MANPAGES)
