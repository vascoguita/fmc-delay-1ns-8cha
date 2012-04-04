#include <stdio.h>

#include "fdelay_lib.h"
#include "rr_io.h"

int spec_fdelay_init(int argc, char *argv[], fdelay_device_t *dev);

main(int argc, char *argv[])
{
    fdelay_device_t dev;
    fdelay_time_t t_cur, t_start;

    if(spec_fdelay_init(argc, argv, &dev) < 0)
    {
        fdelay_show_test_results();

        return -1;
    }

 	fdelay_configure_trigger(&dev, 1,1);

    fdelay_configure_output(&dev,1,1,500000, 100000, 100000, 0);
    fdelay_configure_output(&dev,2,1,500000, 100000, 100000, 0);
    fdelay_configure_output(&dev,3,1,500000, 100000, 100000, 0);
    fdelay_configure_output(&dev,4,1,500000, 100000, 100000, 0);

	fdelay_configure_readout(&dev, 1);
//	fd_update_spll(&dev);
	int64_t prev = 0, dp, pmin=10000000000LL,pmax=0;

	#if 0
	for(;;)
	  {
	    fdelay_time_t ts;
	    if(fdelay_read(&dev, &ts, 1) == 1)
	      {
    		int64_t ts_p = fdelay_to_picos(ts), d;
    		d=ts_p - prev;
    		if(prev > 0)
    		{
            if(d<pmin) pmin=d;
            if(d>pmax) pmax=d;
    		fprintf(stderr,"Got it %lld:%d:%d delta %lld span %lld\n", ts.utc, ts.coarse, ts.frac, d, pmax-pmin);
    		}
    		prev = ts_p;
	      }
	  }
	  #endif

    for(;;)
    {
     fdelay_update_calibration(&dev);
     sleep(1);
    }

}
