#include <stdio.h>

#include "fdelay_lib.h"
#include "rr_io.h"

void my_writel(void *priv, uint32_t data, uint32_t addr)
{
 	rr_writel(data, addr);
}

uint32_t my_readl(void *priv, uint32_t addr)
{
	uint32_t d = rr_readl(addr);
	return d;
}

main()
{
	fdelay_device_t dev;

	rr_init();

	dev.writel = my_writel;
	dev.readl = my_readl;
	dev.base_addr = 0x84000;

	if(fdelay_init(&dev) < 0)
		return -1;
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


}
