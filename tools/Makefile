# user-space tools for spec-fine-delay

# If it exists includes Makefile.specific. In this Makefile, you should put
# specific Makefile code that you want to run before this. For example,
# build a particular environment.
-include Makefile.specific

# include parent_common.mk for buildsystem's defines
REPO_PARENT=../..
-include $(REPO_PARENT)/fmc_common.mk
 
M = $(shell /bin/pwd)/../kernel

DESTDIR ?= /usr/local

CFLAGS += -I$(M) -I../lib -I$(ZIO)/include -Wno-trigraphs -Wall -ggdb $(EXTRACFLAGS)

CC ?= $(CROSS_COMPILE)gcc

progs := fmc-fdelay-list
progs += fmc-fdelay-term
progs += fmc-fdelay-board-time
progs += fmc-fdelay-input
progs += fmc-fdelay-pulse
progs += fmc-fdelay-status

# we are not in the kernel, so we need to piggy-back on "make modules"
all modules: $(progs)

clean:
	rm -f $(progs) *.o *~

$(progs): tools-util.o tools-common.h $(wildcard ../lib/*.[ch])

# make nothing for modules_install, but avoid errors
modules_install:

install:
	install -d $(DESTDIR)/bin
	install -D $(progs) $(DESTDIR)/bin

# we need this as we are out of the kernel
%: %.c $(wildcard *.h)
	$(CC) $(CFLAGS) -O2 $*.c tools-util.o \
		-L../lib -lfdelay -o $@
%.o: %.c  $(wildcard *.h)
	$(CC) $(CFLAGS) -O2 -c $*.c -o $@
