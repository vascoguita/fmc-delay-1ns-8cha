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
    

    fdelay_time_t t_cur, t_start;
    
    fdelay_get_time(&dev, &t_cur);
    
    printf("Current Time: %lld:%d\n", t_cur.utc, t_cur.coarse);
    
    t_start.coarse = 0;
    t_start.utc = t_cur.utc+2;
    t_start.frac = 0;
    
    fdelay_configure_pulse_gen(&dev, 1, 1, t_start, 48000LL, 100000LL, -1);
    t_start.coarse = 124999999;                        
    fdelay_configure_pulse_gen(&dev, 2, 1, t_start, 48000LL, 1000000000000LL, -1);

    for(;;)
        printf("ChannelTrigd: %d %d\n", fdelay_channel_triggered(&dev, 1), fdelay_channel_triggered(&dev, 2));

}
