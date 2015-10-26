# This is not a kbuild Makefile. It is a plain Makefile so it can be copied

# If it exists includes Makefile.specific. In this Makefile, you should put
# specific Makefile code that you want to run before this. For example,
# build a particular environment.
-include Makefile.specific

# include parent_common.mk for buildsystem's defines
REPO_PARENT=../..
-include $(REPO_PARENT)/parent_common.mk

ZIO ?= ../zio

LIB = libfdelay.a
LOBJ := fdelay-init.o
LOBJ += fdelay-time.o
LOBJ += fdelay-tdc.o
LOBJ += fdelay-output.o

CFLAGS = -Wall -ggdb -O2 -I../kernel -I$(ZIO)/include $(EXTRACFLAGS)
LDFLAGS = -L. -lfdelay

DESTDIR ?= /usr/local

modules all: lib

lib: $(LIB)

%: %.c $(LIB)
	$(CC) $(CFLAGS) $*.c $(LDFLAGS) -o $@

$(LIB): $(LOBJ)
	ar r $@ $^

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

