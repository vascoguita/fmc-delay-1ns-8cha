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

VERSION := $(shell git describe --tags --abbrev=0 | tr -d 'v')
SO_VERSION_XYZ := $(shell echo $(VERSION) | grep -o -E "[0-9]+\.[0-9]+\.[0-9]")
SO_VERSION_X := $(shell echo $(SO_VERSION_XYZ) | cut -d "." -f 1)

LIB = libfdelay.a
LIBS = libfdelay.so
LIBS_XYZ = $(LIBS).$(SO_VERSION_XYZ)
LOBJ := fdelay-init.o
LOBJ += fdelay-time.o
LOBJ += fdelay-tdc.o
LOBJ += fdelay-output.o

GIT_VERSION := $(shell git describe --dirty --long --tags)
ZIO_GIT_VERSION := $(shell cd $(ZIO_ABS); git describe --dirty --long --tags)

CFLAGS = -Wall -ggdb -O2 -I../kernel -I$(ZIO_ABS)/include
CFLAGS += -fPIC
CFLAGS += -DGIT_VERSION="\"$(GIT_VERSION)\""
CFLAGS += -DZIO_GIT_VERSION="\"$(ZIO_GIT_VERSION)\""
CFLAGS +=  $(EXTRACFLAGS)
LDFLAGS = -L. -lfdelay

DESTDIR ?= /usr/local

modules all: lib

lib: $(LIB) $(LIBS_XYZ)

%: %.c $(LIB)
	$(CC) $(CFLAGS) $*.c $(LDFLAGS) -o $@

$(LIB): $(LOBJ)
	$(AR) r $@ $^

$(LIBS_XYZ): $(LIB)
	$(CC) -shared  -o $@ -Wl,--whole-archive,-soname,$@ $^ -Wl,--no-whole-archive

clean:
	rm -f $(LIB) $(LIBS_XYZ) .depend *.o *~

.depend: Makefile $(wildcard *.c *.h ../*.h)
	$(CC) $(CFLAGS) -M $(LOBJ:.o=.c) -o $@

install:
	install -d $(DESTDIR)/lib
	install -d $(DESTDIR)/include/fmc-fdelay

	install -m 644 -D $(LIB) $(DESTDIR)/lib
	install -m 0755 $(LIBS_XYZ) $(DESTDIR)/lib
	install -m 644 -D fdelay-lib.h $(DESTDIR)/include/fmc-fdelay
	install -m 644 -D ../kernel/fine-delay.h $(DESTDIR)/include/fmc-fdelay
	ln -sf $(LIBS_XYZ) $(DESTDIR)/lib/$(LIBS).$(SO_VERSION_X)
	ln -sf $(LIBS).$(SO_VERSION_X) $(DESTDIR)/lib/$(LIBS)

modules_install:

-include .depend

