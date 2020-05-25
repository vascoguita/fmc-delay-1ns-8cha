/* Simple demo that reads samples using the read call */

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>
#include <signal.h>
#include <sys/select.h>

#define FDELAY_INTERNAL // for sysfs_get/set
#include "fdelay_lib.h"

#define PACKED __attribute__((packed))

#define MAX_QUEUE_SIZE 1024

struct pulse_queue {
	fdelay_time_t p[MAX_QUEUE_SIZE];
	int head, tail, count, size;
};

void pqueue_clear(struct pulse_queue *p)
{
 	p->head = p->tail = p->count = 0;
 	p->size = MAX_QUEUE_SIZE;
}

void pqueue_push(struct pulse_queue *p, fdelay_time_t *t)
{
	if(p->count == MAX_QUEUE_SIZE)
		return;
		
	p->p[p->tail] = *t;
	p->tail++;
	p->count++;
	if(p->tail == MAX_QUEUE_SIZE)
		p->tail = 0;
}

int pqueue_empty(struct pulse_queue *p)
{
 	return p->count == 0 ? 1 : 0;
}

int pqueue_pop(struct pulse_queue *p, fdelay_time_t *t)
{
	if(p->count == 0)
		return;
		
	*t = p->p[p->head];
	p->head++;
	p->count--;
	if(p->head == MAX_QUEUE_SIZE)
		p->head = 0;
}


#define INPUT_OFFSET -69100
#define OUTPUT_OFFSET 14400

struct pulse_queue outgoing, incoming;

/* Add two timestamps */
static fdelay_time_t ts_add(fdelay_time_t a, fdelay_time_t b)
{
    a.frac += b.frac;
    if(a.frac >= 4096)
    {
        a.frac -= 4096;
		a.coarse++;
    }
    a.coarse += b.coarse;
    if(a.coarse >= 125000000)
    {
        a.coarse -= 125000000;
	a.utc ++;
    }
    a.utc += b.utc;
    return a;
}

fdelay_time_t ts_sub(fdelay_time_t a, fdelay_time_t b)
{
	a.frac -= b.frac;
  	if(a.frac < 0)
   	{
  		a.frac += 4096;
     	a.coarse--;
    }
    a.coarse -= b.coarse;
    if(a.coarse < 0)
    {
    	a.coarse += 125000000;
        a.utc --;
    }
    a.utc-=b.utc;
    return a;
}
             
             
                                                                    

#define MIN_SPACING_US 5000LL
#define MAX_SPACING_US 10000LL

int64_t rrand64(int64_t min, int64_t max)
{
	int i;
	uint64_t tmp = 0;
	for(i=0;i<32;i++) 
		tmp ^= ((uint64_t)random()) << i;
	
	tmp %= (max-min+1);
	return min+tmp;
}

int armed = 0;

void produce_pulses(fdelay_device_t *b)
{
	int64_t delta;
	fdelay_time_t t, td;

	if(armed && !fdelay_channel_triggered(b, 1))
		return ;

	fdelay_get_time(b, &t);
	t.frac = 0;
	delta = rrand64(MIN_SPACING_US * 1000000LL, MAX_SPACING_US*1000000LL);
	td = fdelay_from_picos(delta);
	
//	printf("TD %lld:%d:%d\n", t.utc, t.coarse, t.frac);
	t = ts_add(t, td);

	fdelay_configure_pulse_gen(b, 1, 1, t, 1*1000000, 0, 1);
	pqueue_push(&outgoing, &t);
	
	armed = 1;

}



void enable_wr(fdelay_device_t *b, int index)
{
	int lock_retries = 50;
	printf("Locking to WR network [board=%d]...", index);
	fflush(stdout);
	fdelay_configure_sync(b, FDELAY_SYNC_LOCAL);
	sleep(2);
	return ;
	fdelay_configure_sync(b, FDELAY_SYNC_WR);

	while(fdelay_check_sync(b) <= 0)
	{
		printf(".");
	    fflush(stdout);
	    sleep(1);
	    if(lock_retries-- == 0)
	    {
				fprintf(stderr," WR lock timed out\n");
				exit(1);
	    }
	}

	printf("\n");
	fflush(stdout);
}


int configure_board(fdelay_device_t *b, int argc, char *argv[])
{
	
	if(spec_fdelay_create(b, 1, NULL) < 0)
	{
		printf("Probe failed\n");
		exit(-1);
	}

	if(fdelay_init(b, 0) < 0)
	{
		printf("Init failed\n");
		exit(-1);
	}

	enable_wr(b, 0);
	
	fdelay_configure_trigger(b, 0, 1);	

	fdelay_set_user_offset(b, 1, INPUT_OFFSET);
	fdelay_set_user_offset(b, 0, OUTPUT_OFFSET);

	fdelay_raw_readout(b, 1);	
	fdelay_configure_readout(b, 0);	
	fdelay_configure_readout(b, 1);	
	fdelay_configure_trigger(b, 1, 1);	

	printf("Configuration complete\n");
	fflush(stdout);

    return 0;
}

void handle_readout(fdelay_device_t *b)
{
    int64_t t_ps;
    fdelay_time_t t;
    static time_t start;
    static int prev_seq = -1;
    int done;

    while(fdelay_read(b, &t, 1) == 1)
    {	    
		pqueue_push(&incoming, &t);
	
		t_ps = (t.coarse * 8000LL) + ((t.frac * 8000LL) >> 12);
#if 0
		printf("card 0x%04x, seq %5i: time %lli s, %lli.%03lli ns [count %d] ", 0, t.seq_id, t.utc, t_ps / 1000LL, t_ps % 1000LL, (t.raw.tsbcr >> 10) & 0x3ff);
		
		if(((prev_seq + 1) & 0xffff) != (t.seq_id & 0xffff))
		{
			printf("MISMATCH\n");
		} else printf("\n");
#endif
		
		prev_seq = t.seq_id;
    }
}

void verify()
{
	static int64_t delta_min = 10000000000LL, delta_max = -10000000000LL;
	static int event_count = 0;
	
 	if(!pqueue_empty(&outgoing) && !pqueue_empty(&incoming))
 	{
 	 	fdelay_time_t to, ti, delta;
 	 	int64_t delta_ps;
 	 	int new_ext = 0;
 	 	pqueue_pop(&outgoing, &to);
 	 	pqueue_pop(&incoming, &ti);
 	 	
 	 	delta = ts_sub(to, ti);
 	 	delta_ps = fdelay_to_picos(delta);
 	 	
 	 	if(delta_ps < delta_min)
 	 	{
 	 		delta_min = delta_ps;
 	 		new_ext = 1;
 	 	} else if (delta_ps > delta_max)
 	 	{
 	 		delta_max = delta_ps;
 	 		new_ext = 1;
 	 	}
 	 	 event_count++;
 	 	if(new_ext || (event_count % 10) == 0)
 	 	{
 	 	 
 	 	  	 	printf("events %.8d [q %.5lld:%.8d:%.5d i %.5lld:%.8d:%.5d] delta: %.10lldps [min %.10lldps max %.10lldps span %.10lldps] raw %d %d %d %d \n",
 	 	  	 	event_count,
	 	 	to.utc, to.coarse,to.frac,
	 	 	ti.utc, ti.coarse,ti.frac,
 		 	delta_ps,  delta_min ,delta_max, delta_max-delta_min,
 		 	ti.raw.coarse, ti.raw.start_offset, ti.raw.subcycle_offset, ti.raw.frac-30000);
        	fflush(stdout);
 	 	 //	printf("NewErrorRange: %lld-%lldps\n", delta_min, delta_max); 	 	 	
 	 	 
 	 	}
 	 	
 	 	
 	}
}

int main(int argc, char *argv[])
{
	fdelay_device_t b;

	configure_board(&b, argc, argv);
	pqueue_clear(&incoming);
	pqueue_clear(&outgoing);
	
	for(;;)
	{
		produce_pulses(&b);
		handle_readout(&b);
		verify();
	}
}
