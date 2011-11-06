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
	dev.base_addr = 0x80400;
	
	if(fdelay_init(&dev) < 0)
		return -1;
 	fdelay_configure_trigger(&dev, 1,1);
	
 	fdelay_configure_output(&dev,1,1,500000, 200000);
 	fdelay_configure_output(&dev,2,1,504000, 200000);
 	fdelay_configure_output(&dev,3,1,500000, 200000);
 	fdelay_configure_output(&dev,4,1,500000, 200000);


}