# include parent_common.mk for buildsystem's defines
# use absolute path for REPO_PARENT
REPO_PARENT=$(shell /bin/pwd)/..
-include $(REPO_PARENT)/parent_common.mk

# The user can override, using environment variables, all these three:
FMC_BUS ?= $(shell pwd)/fmc-bus
ZIO ?= $(shell pwd)/zio
SPEC_SW ?= $(shell pwd)/spec-sw

export FMC_BUS
export ZIO
export SPEC_SW

# FMC_BUS_ABS, ZIO_ABS and SPEC_SW_ABS has to be absolut path, due to beeing
# passed to the Kbuild
FMC_BUS_ABS ?= $(abspath $(FMC_BUS) )
ZIO_ABS ?= $(abspath $(ZIO) )
SPEC_SW_ABS ?= $(abspath $(SPEC_SW) )

export FMC_BUS_ABS
export ZIO_ABS
export SPEC_SW_ABS

ZIO_VERSION = $(shell cd $(ZIO); git describe --always --dirty --long --tags)
export ZIO_VERSION

DESTDIR ?= /usr/local

.PHONY: all clean modules install modules_install default
.PHONY: gitmodules prereq prereq_install prereq_install_warn prereq_clean

DIRS = kernel lib tools

all clean modules install modules_install: gitmodules
	@if echo $@ | grep -q install; then $(MAKE) prereq_install_warn; fi
	for d in $(DIRS); do $(MAKE) ZIO=$(ZIO) FMC_BUS=$(FMC_BUS) -C $$d $@ || exit 1; done

all modules: prereq

clean_all: clean prereq_clean

# a hack, to prevent compiling wr-nic.ko, which won't work on older kernels
CONFIG_WR_NIC=n
export CONFIG_WR_NIC

#### The following targets are used to manage prerequisite repositories
gitmodules:
	@test -d fmc-bus/doc || echo "Checking out submodules"
	@test -d fmc-bus/doc || git submodule update --init
	@git submodule update

# The user can override, using environment variables, all these three:
SUBMOD = $(FMC_BUS) $(ZIO) $(SPEC_SW)

prereq:
	for d in $(SUBMOD); do $(MAKE) -C $$d || exit 1; done

prereq_install_warn:
	@test -f .prereq_installed || \
		echo -e "\n\n\tWARNING: Consider \"make prereq_install\"\n"

prereq_install:
	for d in $(SUBMOD); do $(MAKE) -C $$d modules_install || exit 1; done
	touch .prereq_installed

prereq_clean:
	for d in $(SUBMOD); do $(MAKE) -C $$d clean || exit 1; done

include scripts/gateware.mk
