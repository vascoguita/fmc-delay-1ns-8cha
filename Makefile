# include parent_common.mk for buildsystem's defines
# use absolute path for REPO_PARENT
REPO_PARENT=$(shell /bin/pwd)/..
-include $(REPO_PARENT)/parent_common.mk

all: kernel lib tools

# a hack, to prevent compiling wr-nic.ko, which won't work on older kernels
CONFIG_WR_NIC=n
export CONFIG_WR_NIC

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


DIRS = $(FMC_BUS) $(ZIO) $(SPEC_SW) kernel lib tools

$(SPEC_SW): $(FMC_BUS)
kernel: $(FMC_BUS) $(ZIO) $(SPEC_SW)
lib: $(ZIO)
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


SUBMOD = $(FMC_BUS) $(ZIO) $(SPEC_SW)

prereq_install_warn:
	@test -f .prereq_installed || \
		echo -e "\n\n\tWARNING: Consider \"make prereq_install\"\n"

prereq_install:
	for d in $(SUBMOD); do $(MAKE) -C $$d modules_install || exit 1; done
	touch .prereq_installed

$(FMC_BUS): fmc-bus-init_repo
$(ZIO): zio-init_repo
$(SPEC_SW): spec-sw-init_repo

# init submodule if missing
fmc-bus-init_repo:
	@test -d $(FMC_BUS)/doc || ( echo "Checking out submodule $(FMC_BUS)"; git submodule update --init $(FMC_BUS) )

# init submodule if missing
zio-init_repo:
	@test -d $(ZIO)/doc || ( echo "Checking out submodule $(ZIO)" && git submodule update --init $(ZIO) )

# init submodule if missing
spec-sw-init_repo:
	@test -d $(SPEC_SW)/doc || ( echo "Checking out submodule $(SPEC_SW)" && git submodule update --init $(SPEC_SW) )


include scripts/gateware.mk
