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

int configure_board(fdelay_device_t *b, int argc, char *argv[])
{
	fdelay_time_t t;
	
	if(spec_fdelay_init(b,argc,argv) < 0)
	{
		printf("Init failed\n");
		exit(-1);
	}

	fdelay_configure_sync(b, FDELAY_SYNC_LOCAL);

	fdelay_get_time(b, &t);
	t.frac = 0;
	t.coarse = 0;
	t.utc += 2;

	sleep(1);
	
	fdelay_configure_pulse_gen(b, 1, 1, t, 10 * 1000000, 99999990, -1);

	fdelay_configure_trigger(b, 0, 1);	

	fdelay_raw_readout(b, 0);	
	fdelay_configure_readout(b, 0);	
	fdelay_configure_readout(b, 1);	
	fdelay_configure_trigger(b, 1, 0);	

	printf("Configuration complete\n");
	fflush(stdout);

    return 0;
}

void handle_readout(fdelay_device_t *b, int n_samples)
{
    int64_t t_ps;
    fdelay_time_t t;
    static time_t start;
    static int64_t t_prev;
    static int prev_seq = -1;
    int done;

	for(;;)
	    while(fdelay_read(b, &t, 1) == 1)
    	{	    
			t_ps = (t.coarse * 8000LL) + ((t.frac * 8000LL) >> 12);
			int64_t delta =  t_ps-t_prev;
		
			if(delta < 0)
				delta += 1000000000000LL;
		
			if(prev_seq >= 0)
				printf("Samp %lli.%03lli %lli\n", t_ps / 1000LL, t_ps % 1000LL, delta) ;
			
			prev_seq = t.seq_id;
			t_prev=t_ps;
			n_samples--;
			if(!n_samples) return;
    	}
}

int main(int argc, char *argv[])
{
	fdelay_device_t b;

	configure_board(&b, argc, argv);

	handle_readout(&b, 40000);
}
