# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	$(MAKE) -C drawings
	$(MAKE) doxygen TARGET=$@
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

GIT_VERSION = $(shell git describe --dirty --long --tags)

GIT_VERSION = $(shell git describe --dirty --long --tags)
doxygen:
ifeq ($(TARGET),clean)
	@rm -rf doxygen-fd-output .doxystamp
else
	$(MAKE) .doxystamp
endif

# List of Doxygen folders to consider
DOXINPUT := ../../lib
DOXINPUT += ../../kernel/fine-delay.h
DOXEXCL  :=  ../../lib/PyFmcFineDelay

# List of actual Doxygen source files
DOXSRC   = $(shell find $(DOXINPUT) -type f -name '*.[chS]')

.doxystamp: $(DOXSRC)
	GIT_VERSION=$(GIT_VERSION) DOXINPUT="$(DOXINPUT)" DOXEXCL="$(DOXEXCL)" doxygen ./doxygen-fd-config
	@touch .doxystamp
