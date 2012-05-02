#include <stdio.h>

#include "fdelay_lib.h"
#include "rr_io.h"

extern int spec_fdelay_init(int argc, char *argv[], fdelay_device_t *dev);

main(int argc, char *argv[])
{
    fdelay_device_t dev;
    fdelay_time_t t;

    /* Initialize the fine delay generator */
    if(spec_fdelay_init(argc, argv, &dev) < 0)
    {
        fdelay_show_test_results();
        return -1;
    }

    /* Enable trigger input and 50 ohm termination */

    /* Enable all outputs and set them to 500 ns delay, 100 ns pulse width, single output pulse per trigger */

/*    fdelay_configure_output(&dev,1,1,500000, 100000, 100000, 1);
    fdelay_configure_output(&dev,2,1,500000, 100000, 100000, 1);
    fdelay_configure_output(&dev,3,1,500000, 100000, 100000, 1);
    fdelay_configure_output(&dev,4,1,500000, 100000, 100000, 1);*/
    
    t.utc = 0;
    t.coarse = 0;
    
	fdelay_set_time(&dev, t);

	fdelay_configure_sync(&dev, FDELAY_SYNC_WR);
	fprintf(stderr, "Syncing with WR Timebase...\n");
	while(!fdelay_check_sync(&dev))
		fprintf(stderr, ".");
	fprintf(stderr, " locked!\n");

    fdelay_configure_trigger(&dev, 1, 0);
	fdelay_configure_readout(&dev, 1);//int enable)

	int seq_prev = 0;
	int64_t t_prev = 0;
	
	#if 1
	for(;;)
	{
		fdelay_time_t ts;
		int64_t ts_i;
		
		if(fdelay_read(&dev, &ts, 1) == 1)
		{
			ts_i = fdelay_to_picos(ts);
			fprintf(stderr,"ts = %-20lld ps, delta = %-20lld, seq = %-6d seq_delta=%-6d\n", 
			ts_i, ts_i-t_prev, ts.seq_id, ts.seq_id-seq_prev);
			seq_prev = ts.seq_id;
			t_prev= ts_i;
		}
	}
	#endif

//	fdelay_
	
	for(;;)
	{
	}
	

}
