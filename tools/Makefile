# user-space tools for spec-fine-delay

M = $(shell /bin/pwd)/../kernel

HOST_EXTRACFLAGS += -I$(M) -I../lib -I$(ZIO)/include -Wno-trigraphs -Wall -ggdb

HOSTCC ?= gcc

hostprogs-y := fmc-fdelay-list
hostprogs-y += fmc-fdelay-term
hostprogs-y += fmc-fdelay-board-time
hostprogs-y += fmc-fdelay-input
hostprogs-y += fmc-fdelay-pulse

# we are not in the kernel, so we need to piggy-back on "make modules"
all modules: $(hostprogs-y)

clean:
	rm -f $(hostprogs-y) *.o *~

$(hostprogs-y): tools-common.h $(wildcard ../lib/*.[ch])

# make nothing for modules_install, but avoid errors
modules_install install:

# we need this as we are out of the kernel
%: %.c
	$(HOSTCC) $(HOST_EXTRACFLAGS) -O2 -Wall $*.c -L../lib -lfdelay -o $@
