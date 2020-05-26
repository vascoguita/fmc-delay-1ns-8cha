# include parent_common.mk for buildsystem's defines
# use absolute path for REPO_PARENT
REPO_PARENT ?= $(shell /bin/pwd)/..
-include $(REPO_PARENT)/parent_common.mk

all: kernel lib tools

# The user can override, using environment variables, all these three:
ZIO ?= zio

# ZIO_ABS has to be absolut path, due to beeing
# passed to the Kbuild
ZIO_ABS ?= $(abspath $(ZIO) )

export ZIO_ABS

ZIO_VERSION = $(shell cd $(ZIO_ABS); git describe --always --dirty --long --tags)
export ZIO_VERSION


DIRS = $(ZIO_ABS) kernel lib tools

$(SPEC_SW_ABS):
kernel: $(ZIO_ABS)
lib: $(ZIO_ABS)
tools: lib

DESTDIR ?= /usr/local

.PHONY: all clean modules install modules_install $(DIRS)
.PHONY: gitmodules prereq_install prereq_install_warn

install modules_install: prereq_install_warn

all clean modules install modules_install: $(DIRS)

clean: TARGET = clean
modules: TARGET = modules
install: TARGET = install
modules_install: TARGET = modules_install


$(DIRS):
	$(MAKE) -C $@ $(TARGET)


SUBMOD = $(ZIO_ABS)

prereq_install_warn:
	@test -f .prereq_installed || \
		echo -e "\n\n\tWARNING: Consider \"make prereq_install\"\n"

prereq_install:
	for d in $(SUBMOD); do $(MAKE) -C $$d modules_install || exit 1; done
	touch .prereq_installed

$(ZIO_ABS): zio-init_repo

# init submodule if missing
zio-init_repo:
	@test -d $(ZIO_ABS)/doc || ( echo "Checking out submodule $(ZIO_ABS)" && git submodule update --init $(ZIO_ABS) )

include scripts/gateware.mk
