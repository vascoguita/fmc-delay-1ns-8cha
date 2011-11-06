CFLAGS = -I../include -g -Imini_bone

OBJS_LIB = fdelay_lib.o rr_io.o  i2c_master.o mini_bone/minibone_lib.o mini_bone/ptpd_netif.o  fdelay_bus.o

all:	$(OBJS_LIB)
		gcc -shared -o libfinedelay.so $(OBJS_LIB)

clean:	
		rm -f libfinedelay.so $(OBJS_LIB)