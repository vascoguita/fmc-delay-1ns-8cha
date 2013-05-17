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

static int64_t min_gap, max_gap;
static fdelay_time_t t;

void produce_pulses(fdelay_device_t *b)
{
	int64_t delta;
	fdelay_time_t  td;

	if(armed && !fdelay_channel_triggered(b, 1))
		return ;

	delta = rrand64(min_gap, max_gap);
	fdelay_get_time(b, &t);

	td = fdelay_from_picos(delta);
	
	t = ts_add(t, td);
	

	fdelay_configure_pulse_gen(b, 1, 1, t, min_gap/3, 0, 1);
	
	armed = 1;
}


int main(int argc, char *argv[])
{
	if(argc < 4)
	{
	    fprintf(stderr, "usage: %s card_location min_period[us] max_period[us] count\n", argv[0]);
	    return 0;
	}
	
	fdelay_device_t *b = fdelay_create();
	
	if(fdelay_probe(b, argv[1]) < 0)
	{
	    fprintf(stderr, "Probing failed\n");
	    return 0;
	}

	
	fdelay_init(b, 0);
	fdelay_configure_trigger(b, 0, 0);	
	
	int count = atoi(argv[4]);

	min_gap =(int64_t) (atof(argv[2]) * 1000000.0);
	max_gap =(int64_t) (atof(argv[3]) * 1000000.0);
	
	int i = 0;


	while(count < 0 || (i < count))
	{
    	    produce_pulses(b);
	    i++;
	}

	printf("generated %d pulses\n", i);

	return 0;
}
