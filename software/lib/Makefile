SPEC_SW ?= $(shell readlink -f ~/wr-repos/spec-sw)
ETHERBONE ?= $(shell readlink -f ~/wr-repos/etherbone-core/api)

OBJS = fdelay_lib.o i2c_master.o onewire.o fdelay_bus.o fdelay_dmtd_calibration.o sveclib/sveclib.o sveclib/libvmebus.o speclib/speclib.o

CFLAGS = -I../include -g -Imini_bone -Ispec/tools -Isveclib -I.

#ifeq ($(SPEC_SW),)
#throw_error:
#	@echo "SPEC software package location environment variable is not set. Can't compile :("
#endif

all:	lib

#spec:	
#		ln -s $(SPEC_SW) spec
#		ln -s $(ETHERBONE) etherbone

lib:	$(OBJS)
		gcc -shared -o libfinedelay.so $(OBJS) 
		ar rc libfinedelay.a $(OBJS)

clean:	
		rm -f *.o libfinedelay.so
