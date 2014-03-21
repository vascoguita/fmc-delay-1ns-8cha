# user-space tools for spec-fine-delay

M = $(shell /bin/pwd)/../kernel

HOST_EXTRACFLAGS += -I$(M) -I../lib -I$(ZIO)/include -Wno-trigraphs -Wall -ggdb

HOSTCC ?= gcc

hostprogs-y := fmc-fdelay-list
hostprogs-y += fmc-fdelay-term
hostprogs-y += fmc-fdelay-board-time
hostprogs-y += fmc-fdelay-input
hostprogs-y += fmc-fdelay-pulse
hostprogs-y += fmc-fdelay-status

# we are not in the kernel, so we need to piggy-back on "make modules"
all modules: $(hostprogs-y)

clean:
	rm -f $(hostprogs-y) *.o *~

$(hostprogs-y): tools-util.o tools-common.h $(wildcard ../lib/*.[ch])

# make nothing for modules_install, but avoid errors
modules_install install:

# we need this as we are out of the kernel
%: %.c $(wildcard *.h)
	$(HOSTCC) $(HOST_EXTRACFLAGS) -O2 -Wall $*.c tools-util.o \
		-L../lib -lfdelay -o $@
%.o: %.c  $(wildcard *.h)
	$(HOSTCC) $(HOST_EXTRACFLAGS) -O2 -Wall -c $*.c -o $@
