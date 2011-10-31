CFLAGS = -I/home/slayer/rr/gnurabbit/kernel -Iinclude -g

OBJS = fdelay_lib.o fdelay_test.o rr_io.o 
all:	$(OBJS)
		gcc -o fd_test  $(OBJS) -lm

clean:	
		rm -f fd_test $(OBJS)