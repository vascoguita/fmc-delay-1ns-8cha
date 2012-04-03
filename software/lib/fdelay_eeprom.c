#include <stdio.h>

#include "fdelay_lib.h"
#include "fdelay_private.h"
#include "rr_io.h"
#include "i2c_master.h"

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
    struct fine_delay_calibration cal;
    
	rr_init(RR_DEVSEL_UNUSED, RR_DEVSEL_UNUSED);

	dev.writel = my_writel;
	dev.readl = my_readl;
	dev.base_addr = 0x84000;

	if(fdelay_init(&dev) < 0)
		return -1;


    
    cal.magic = 0xf19ede1a;
    cal.zero_offset[0] = 63000;
    cal.zero_offset[1] = 63000;
    cal.zero_offset[2] = 63000;
    cal.zero_offset[3] = 63000;
    cal.tdc_zero_offset = 35600;
    cal.frr_poly[0] = -165202LL;
    cal.frr_poly[1] = -29825595LL;
    cal.frr_poly[2] = 3801939743082LL;
    cal.tdc_zero_offset = 35600;
    cal.atmcr_val =  2 | (1000 << 4);
    cal.adsfr_val = 56648;
    cal.acam_start_offset = 10000;

    printf("Writing EEPROM...");
    eeprom_write(&dev, EEPROM_ADDR, 0, &cal, sizeof(struct fine_delay_calibration));
    printf(" done.\n");

}
