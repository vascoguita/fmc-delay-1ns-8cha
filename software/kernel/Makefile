# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2019 CERN

-include Makefile.specific
# include parent_common.mk for buildsystem's defines
#use absolute path for REPO_PARENT
-include $(REPO_PARENT)/parent_common.mk

CPPCHECK ?= cppcheck
FLAWFINDER ?= flawfinder
DKMS ?= 0
CURDIR := $(shell /bin/pwd)
KVERSION ?= $(shell uname -r)
KERNELSRC ?= /lib/modules/$(KVERSION)/build

ifdef REPO_PARENT
ZIO ?= $(REPO_PARENT)/zio
FMC ?= $(REPO_PARENT)/fmc-sw
endif

ifeq ($(DKMS), 1)
# Take last installed version (if installed using RPM it should be OK)
ZIO_VERSION ?= $(shell basename $(shell ls -d $(DKMSTREE)/zio/* | grep -E "\/[0-9]+\.[0-9]+\.[0-9]+" | sort -V | tail -n 1))
ZIO_ABS ?= $(DKMSTREE)/zio/$(ZIO_VERSION)/source
ZIO_EXTRA_SYMBOLS-y = $(DKMSTREE)/zio/kernel-$(KVERSION)-$(shell uname -p)/module/Module.symvers
else

ifndef ZIO
$(error "Missing ZIO environment variable")
endif
ifndef FMC
$(error "Missing FMC environment variable")
endif

ZIO_ABS ?= $(abspath $(ZIO))
ZIO_EXTRA_SYMBOLS-y = $(ZIO_ABS)/drivers/zio/Module.symvers
ZIO_VERSION ?= $(shell cd $(ZIO_ABS); git describe --always --dirty --long --tags)
FMC_ABS ?= $(abspath $(FMC))
FMC_EXTRA_SYMBOLS-y = $(FMC_ABS)/drivers/fmc/Module.symvers

endif

GIT_VERSION = $(shell git describe --always --dirty --long --tags)

all: modules

clean modules:
	$(MAKE) -C $(KERNELSRC) M=$(CURDIR) ZIO_ABS=$(ZIO_ABS) FMC_ABS=$(FMC_ABS) \
		ZIO_EXTRA_SYMBOLS-y=$(ZIO_EXTRA_SYMBOLS-y) \
		FMC_EXTRA_SYMBOLS-y=$(FMC_EXTRA_SYMBOLS-y) \
		ZIO_VERSION=$(ZIO_VERSION) \
		GIT_VERSION=$(GIT_VERSION) \
		$@

install modules_install: modules
	$(MAKE) -C $(KERNELSRC) M=$(CURDIR) modules_install

cppcheck:
	$(CPPCHECK) -q -I. -I$(ZIO_ABS)/include -I$(FMC_BUS_ABS)/ -I$(KERNEL_SRC)/include  --enable=all *.c *.h

flawfinder:
	$(FLAWFINDER) -SQDC --error-level=3 .

.PHONY: all cppcheck clean clean flawfinder install modules modules_install
