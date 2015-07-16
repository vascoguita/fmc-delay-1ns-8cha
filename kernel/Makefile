LINUX ?= /lib/modules/$(shell uname -r)/build

ZIO ?= $(src)/../zio
FMC_BUS ?= $(src)/../fmc-bus

KBUILD_EXTRA_SYMBOLS := \
	$(ZIO)/Module.symvers \
	$(FMC_BUS)/kernel/Module.symvers

GIT_VERSION = $(shell cd $(src); git describe --dirty --long --tags)

# For this CSM_VERSION, please see ohwr.org/csm documentation
ifdef CONFIG_CSM_VERSION
  ccflags-y += -D"CERN_SUPER_MODULE=MODULE_VERSION(\"$(CONFIG_CSM_VERSION)\")"
else
  ccflags-y += -DCERN_SUPER_MODULE=""
endif

ccflags-y += \
	-I$(ZIO)/include \
	-I$(FMC_BUS)/kernel/include \
	-I$(FMC_BUS)/kernel/include/linux \
	-I$(FMC_BUS) \
	-I$(src)

ccflags-y += -DGIT_VERSION=\"$(GIT_VERSION)\"
#ccflags-y += -DDEBUG

# Extract ZIO minimum compatible version
ccflags-y += -D__ZIO_MIN_MAJOR_VERSION=$(shell echo $(ZIO_VERSION) | cut -d '-' -f 2 | cut -d '.' -f 1; )
ccflags-y += -D__ZIO_MIN_MINOR_VERSION=$(shell echo $(ZIO_VERSION) | cut -d '-' -f 2 | cut -d '.' -f 2; )

subdirs-ccflags-y = $(ccflags-y)

obj-m := fmc-fine-delay.o

fmc-fine-delay-objs	=  fd-zio.o fd-irq.o fd-core.o
fmc-fine-delay-objs	+= onewire.o spi.o i2c.o gpio.o
fmc-fine-delay-objs	+= acam.o calibrate.o pll.o time.o
fmc-fine-delay-objs	+= calibration.o fmc-util.o
fmc-fine-delay-objs	+= ../fmc-bus/sdb-lib/access.o
fmc-fine-delay-objs	+= ../fmc-bus/sdb-lib/glue.o

all modules:
	$(MAKE) -C $(LINUX) M=$(shell /bin/pwd) modules

install modules_install:
	$(MAKE) -C $(LINUX) M=$(shell /bin/pwd) modules_install

# be able to run the "clean" rule even if $(LINUX) is not valid
clean:
	rm -rf *.o *~  .*.cmd *.ko *.mod.c .tmp_versions Module.symvers \
		Module.markers modules.order
