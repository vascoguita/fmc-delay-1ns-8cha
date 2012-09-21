SPEC_SW ?= $(shell readlink -f ~/wr-repos/spec-sw)
ETHERBONE ?= $(shell readlink -f ~/wr-repos/etherbone-core/api)

OBJS = fdelay_lib.o i2c_master.o onewire.o fdelay_bus.o spec/tools/speclib.o spec/kernel/loader-ll.o fdelay_dmtd_calibration.o simple-eb.o 

CFLAGS = -I../include -g -Imini_bone -Ispec/tools -Ietherbone

ifeq ($(SPEC_SW),)
throw_error:
	@echo "SPEC software package location environment variable is not set. Can't compile :("
endif

all:	spec lib

spec:	
		ln -s $(SPEC_SW) spec
		ln -s $(ETHERBONE) etherbone

lib:	$(OBJS)
		gcc -shared -o libfinedelay.so $(OBJS) -letherbone
		ar rc libfinedelay.a $(OBJS)

clean:	
		rm -f *.o libfinedelay.so
