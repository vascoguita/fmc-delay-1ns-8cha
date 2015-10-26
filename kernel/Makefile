# include parent_common.mk for buildsystem's defines
# use absolute path for REPO_PARENT
REPO_PARENT=$(shell /bin/pwd)/../..
-include $(REPO_PARENT)/parent_common.mk

LINUX ?= /lib/modules/$(shell uname -r)/build

FMC_BUS ?= $(shell pwd)/../fmc-bus
ZIO ?= $(shell pwd)/../zio

# FMC_BUS_ABS, ZIO_ABS and SPEC_SW_ABS has to be absolut path, due to beeing
# passed to the Kbuild
FMC_BUS_ABS ?= $(abspath $(FMC_BUS) )
ZIO_ABS ?= $(abspath $(ZIO) )

GIT_VERSION = $(shell git describe --dirty --long --tags)
export GIT_VERSION

ZIO_VERSION = $(shell cd $(ZIO_ABS); git describe --always --dirty --long --tags)
export ZIO_VERSION

all modules:
	rm -f fmc-bus-link
	ln -s $(FMC_BUS_ABS) fmc-bus-link
	$(MAKE) -C $(LINUX) M=$(shell /bin/pwd) FMC_BUS_ABS=$(FMC_BUS_ABS) ZIO_ABS=$(ZIO_ABS) modules
	rm -f fmc-bus-link

install modules_install: modules
	$(MAKE) -C $(LINUX) M=$(shell /bin/pwd) modules_install

# be able to run the "clean" rule even if $(LINUX) is not valid
clean:
	rm -rf *.o *~  .*.cmd *.ko *.mod.c .tmp_versions Module.symvers \
		Module.markers modules.order
