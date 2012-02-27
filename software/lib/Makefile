CFLAGS = -I../include -g -Imini_bone -Ispll

OBJS_LIB = fdelay_lib.o rr_io.o  i2c_master.o onewire.o mini_bone/minibone_lib.o mini_bone/ptpd_netif.o  fdelay_bus.o 

all:    testprog lib testprog2

lib:	$(OBJS_LIB)
		gcc -shared -o libfinedelay.so $(OBJS_LIB)

testprog:	lib fdelay_test.o
		gcc -o fdelay_test $(OBJS_LIB) fdelay_test.o -lm

testprog2:	lib fdelay_cal.o
		gcc -o fdelay_cal $(OBJS_LIB) fdelay_cal.o -lm

clean:	
		rm -f libfinedelay.so $(OBJS_LIB)