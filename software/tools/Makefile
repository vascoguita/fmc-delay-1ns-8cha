# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: LGPL-2.1-or-later

# user-space tools for spec-fine-delay

# If it exists includes Makefile.specific. In this Makefile, you should put
# specific Makefile code that you want to run before this. For example,
# build a particular environment.
-include Makefile.specific

# include parent_common.mk for buildsystem's defines
IGNORE_CPU_SUFFIX := y
REPO_PARENT ?= $(pwd)/../../..
-include $(REPO_PARENT)/parent_common.mk

DESTDIR ?= /usr/local

GIT_VERSION := $(shell git describe --dirty --long --tags)

LIBFD := ../lib
CFLAGS += -I../kernel -I$(LIBFD) -Wno-trigraphs -Wall -Werror -ggdb $(EXTRACFLAGS)
CFLAGS += -DGIT_VERSION="\"$(GIT_VERSION)\""

LDFLAGS = -L$(LIBFD)
LDLIBS = -lfdelay

CC ?= $(CROSS_COMPILE)gcc

progs := fmc-fdelay-list
progs += fmc-fdelay-term
progs += fmc-fdelay-board-time
progs += fmc-fdelay-input
progs += fmc-fdelay-pulse
progs += fmc-fdelay-status

CPPCHECK ?= cppcheck
FLAWFINDER ?= flawfinder

# we are not in the kernel, so we need to piggy-back on "make modules"
all modules: $(progs) fmc-fdelay-calibration

clean:
	rm -f $(progs) fmc-fdelay-calibration *.o *~

COMMON_SRCS = tools-util.c

$(progs): $(COMMON_SRCS:.c=.o)

fmc-fdelay-calibration:

# make nothing for modules_install, but avoid errors
modules_install:

install:
	install -d $(DESTDIR)/bin
	install -D fmc-fdelay-calibration $(DESTDIR)/bin
	install -D $(progs) $(DESTDIR)/bin

cppcheck:
	$(CPPCHECK) -q -I. -I../kernel -I$(LIBFD) --suppress=missingIncludeSystem --enable=all *.c *.h

flawfinder:
	$(FLAWFINDER) -SQDC --error-level=5 .

.PHONY: cppcheck flawfinder
