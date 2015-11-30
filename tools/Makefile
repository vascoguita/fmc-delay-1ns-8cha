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

CFLAGS += -I$(M) -I../lib -Wno-trigraphs -Wall -ggdb $(EXTRACFLAGS)

LDFLAGS = -L../lib
LDLIBS = -lfdelay

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

COMMON_SRCS = tools-util.c

$(progs): $(COMMON_SRCS:.c=.o)

# make nothing for modules_install, but avoid errors
modules_install:

install:
	install -d $(DESTDIR)/bin
	install -D $(progs) $(DESTDIR)/bin

