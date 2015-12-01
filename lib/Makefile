# This is not a kbuild Makefile. It is a plain Makefile so it can be copied

# If it exists includes Makefile.specific. In this Makefile, you should put
# specific Makefile code that you want to run before this. For example,
# build a particular environment.
-include Makefile.specific

# include parent_common.mk for buildsystem's defines
REPO_PARENT=../..
-include $(REPO_PARENT)/parent_common.mk


ZIO ?= ../zio
ZIO_ABS ?= $(abspath $(ZIO) )

LIB = libfdelay.a
LOBJ := fdelay-init.o
LOBJ += fdelay-time.o
LOBJ += fdelay-tdc.o
LOBJ += fdelay-output.o

GIT_VERSION := $(shell git describe --dirty --long --tags)
ZIO_GIT_VERSION := $(shell cd $(ZIO_ABS); git describe --dirty --long --tags)

CFLAGS = -Wall -ggdb -O2 -I../kernel -I$(ZIO_ABS)/include $(EXTRACFLAGS)
CFLAGS += -DGIT_VERSION="\"$(GIT_VERSION)\""
CFLAGS += -DZIO_GIT_VERSION="\"$(ZIO_GIT_VERSION)\""
LDFLAGS = -L. -lfdelay

DESTDIR ?= /usr/local

modules all: lib

lib: $(LIB)

%: %.c $(LIB)
	$(CC) $(CFLAGS) $*.c $(LDFLAGS) -o $@

$(LIB): $(LOBJ)
	$(AR) r $@ $^

clean:
	rm -f $(LIB) .depend *.o *~

.depend: Makefile $(wildcard *.c *.h ../*.h)
	$(CC) $(CFLAGS) -M $(LOBJ:.o=.c) -o $@

install:
	install -d $(DESTDIR)/lib
	install -d $(DESTDIR)/include/fmc-fdelay

	install -m 644 -D $(LIB) $(DESTDIR)/lib
	install -m 644 -D fdelay-lib.h $(DESTDIR)/include/fmc-fdelay
	install -m 644 -D ../kernel/fine-delay.h $(DESTDIR)/include/fmc-fdelay

modules_install:

-include .depend

