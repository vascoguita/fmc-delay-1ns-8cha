# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# older user-space tools for spec-fine-delay

# If it exists includes Makefile.specific. In this Makefile, you should put
# specific Makefile code that you want to run before this. For example,
# build a particular environment.
-include Makefile.specific

M = $(shell /bin/pwd)/../kernel

ZIO_ABS_PATH ?= $(REPO_PARENT)/zio

HOST_EXTRACFLAGS += -I$(M) -I../lib -I$(ZIO_ABS_PATH)/include -Wno-trigraphs -Wall -ggdb

HOSTCC ?= gcc

hostprogs-y := fd-raw-input
hostprogs-y += fd-raw-gettime
hostprogs-y += fd-raw-settime
hostprogs-y += parport-burst
hostprogs-y += fd-raw-output
hostprogs-y += fd-raw-perf

# we are not in the kernel, so we need to piggy-back on "make modules"
all modules: $(hostprogs-y)

clean:
	rm -f $(hostprogs-y) *.o *~

# make nothing for modules_install, but avoid errors
modules_install install:

# we need this as we are out of the kernel
%: %.c
	$(HOSTCC) $(HOST_EXTRACFLAGS) -O2 -Wall $^ -L../lib -lfdelay -o $@
