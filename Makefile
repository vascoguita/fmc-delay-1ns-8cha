# include parent_common.mk for buildsystem's defines
# use absolute path for REPO_PARENT
REPO_PARENT=$(shell /bin/pwd)/..
-include $(REPO_PARENT)/parent_common.mk

FMC_BUS := $(shell scripts/check-submodule fmc-bus $(FMC_BUS))
ZIO 		:= $(shell scripts/check-submodule zio $(ZIO))
ZIO_VERSION = $(shell cd $(ZIO); git describe --always --dirty --long --tags)
export ZIO_VERSION
SPEC_SW := $(shell scripts/check-submodule spec-sw $(SPEC_SW))

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
