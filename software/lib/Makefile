CFLAGS = -I../include -g -Imini_bone -Ispll 

#uncomment for extra tests (DAC, output stage INL/DNL)
#CFLAGS += -DPERFORM_LONG_TESTS

OBJS_LIB = fdelay_lib.o i2c_master.o onewire.o mini_bone/minibone_lib.o mini_bone/ptpd_netif.o  spec_common.o spec/speclib.o fdelay_dmtd_calibration.o

all:    testprog lib gs rp-test sweep-test

lib:	$(OBJS_LIB)
		gcc -shared -o libfinedelay.so $(OBJS_LIB)

testprog:		lib fdelay_test.o
		gcc -o fdelay_test $(OBJS_LIB) fdelay_test.o -lm

gs:		lib fdelay-gs.o
		gcc -o fdelay-gs $(OBJS_LIB) fdelay-gs.o -lm

rp-test: lib random_pulse_test.o
		gcc -o fdelay-random-test $(OBJS_LIB) random_pulse_test.o -lm


sweep-test: lib sweep_test.o
		gcc -o fdelay-sweep-test $(OBJS_LIB) sweep_test.o -lm

clean:	
		rm -f *.o fdelay-random-test fdelay-gs fdelay_pps_demo fdelay_test