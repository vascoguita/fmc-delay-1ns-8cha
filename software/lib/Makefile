CFLAGS = -I../include -g -Imini_bone -Ispll 

#uncomment for extra tests (DAC, output stage INL/DNL)
#CFLAGS += -DPERFORM_LONG_TESTS

OBJS_LIB = fdelay_lib.o i2c_master.o onewire.o mini_bone/minibone_lib.o mini_bone/ptpd_netif.o  spec_common.o 

all:    testprog lib gs

lib:	$(OBJS_LIB)
		gcc -shared -o libfinedelay.so $(OBJS_LIB)

testprog:	lib fdelay_pps_demo.o
		gcc -o fdelay_pps_demo $(OBJS_LIB) fdelay_pps_demo.o -lm

gs:		lib fdelay-gs.o
		gcc -o fdelay-gs $(OBJS_LIB) fdelay-gs.o -lm

