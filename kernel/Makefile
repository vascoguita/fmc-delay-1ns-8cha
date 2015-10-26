LINUX ?= /lib/modules/$(shell uname -r)/build

ZIO ?= $(src)/../zio
FMC_BUS ?= $(src)/../fmc-bus

GIT_VERSION = $(shell git describe --dirty --long --tags)
export GIT_VERSION

ZIO_VERSION = $(shell cd $(ZIO); git describe --always --dirty --long --tags)
export ZIO_VERSION

all modules:
	rm -f fmc-bus-link
	ln -s $(FMC_BUS) fmc-bus-link
	$(MAKE) -C $(LINUX) M=$(shell /bin/pwd) modules
	rm -f fmc-bus-link

install modules_install: modules
	$(MAKE) -C $(LINUX) M=$(shell /bin/pwd) modules_install

# be able to run the "clean" rule even if $(LINUX) is not valid
clean:
	rm -rf *.o *~  .*.cmd *.ko *.mod.c .tmp_versions Module.symvers \
		Module.markers modules.order
