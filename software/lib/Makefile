
OBJS = fdelay_lib.o i2c_master.o onewire.o spec_common.o spec/tools/speclib.o spec/kernel/loader-ll.o fdelay_dmtd_calibration.o

CFLAGS = -I../include -g -Imini_bone -Ispec/tools

ifeq ($(SPEC_SW),)
throw_error:
	@echo "SPEC software package location environment variable is not set. Can't compile :("
endif

all:	spec lib

spec:	
		ln -s $(SPEC_SW) spec

lib:	$(OBJS)
		gcc -shared -o libfinedelay.so $(OBJS)
		ar rc libfinedelay.a $(OBJS)

clean:	
		rm -f *.o libfinedelay.so
