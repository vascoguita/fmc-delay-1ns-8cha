#include <stdio.h>
#include <stdint.h>
#include <getopt.h>

#include "spec/speclib.h"
#include "fdelay_lib.h"

void loader_low_level(){}; /* fixme: include the kernel file */

static void fd_spec_writel(void *priv, uint32_t data, uint32_t addr)
{
	spec_writel(priv, data, addr);
}

static uint32_t fd_spec_readl(void *priv, uint32_t addr)
{
	return spec_readl(priv, addr);
}

int spec_fdelay_init_bd(fdelay_device_t *dev, int bus, int dev_fn, uint32_t base)
{
	dev->priv_io = spec_open(bus, dev_fn);

	if(!dev->priv_io)
	{
	 	fprintf(stderr,"Can't map the SPEC @ %x:%x\n", bus, dev_fn);
	 	return -1;
	}

	dev->writel = fd_spec_writel;
	dev->readl = fd_spec_readl;
	dev->base_addr = base;

	spec_vuart_init(dev->priv_io, 0xe0500); /* for communication with WRCore during DMTD calibration */

	if(fdelay_init(dev) < 0)
		return -1;

    return 0;
}

int spec_fdelay_init(fdelay_device_t *dev, int argc, char *argv[])
{
	int bus = -1, dev_fn = -1, c;
	uint32_t base = 0x80000;

	while ((c = getopt (argc, argv, "b:d:f:")) != -1)
	{
		switch(c)
		{
		case 'b':
			sscanf(optarg, "%i", &bus);
			break;
		case 'd':
			sscanf(optarg, "%i", &dev_fn);
			break;
		case 'u':
			sscanf(optarg, "%i", &base);
			break;
		default:
			fprintf(stderr,
				"Use: \"%s [-b bus] [-d devfn] [-u Fine Delay base] [-k]\"\n", argv[0]);
			fprintf(stderr,
				"By default, the first available SPEC is used and the FD is assumed at 0x%x.\n", base);
			return -1;
		}
	}

	return spec_fdelay_init_bd(dev, bus, dev_fn, base);
}


