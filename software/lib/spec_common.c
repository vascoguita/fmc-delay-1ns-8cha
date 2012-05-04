#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "fdelay_lib.h"
#include "rr_io.h"

void spec_writel(void *priv, uint32_t data, uint32_t addr)
{
 	rr_writel(data, addr);
}

uint32_t spec_readl(void *priv, uint32_t addr)
{
	uint32_t d = rr_readl(addr);
	return d;
}

int spec_fdelay_init(int argc, char *argv[], fdelay_device_t *dev)
{
    int bus = RR_DEVSEL_UNUSED, devfn = RR_DEVSEL_UNUSED;
    int opt = 0;
    char fw_name[1024];
    
    strcpy(fw_name, "spec_top.bin");
    while ((opt = getopt(argc, argv, "hb:d:f:")) != -1) {
        switch (opt) {
            case 'h':
                printf("Usage: %s [-b PCI_bus] [-d PCI dev/func] [-f firmware file]\n", argv[0]);
                printf("By default, the first detected SPEC is initialized with 'spec_top.bin' firmware\n");
                return 0;
            case 'b':
                sscanf(optarg, "%x", &bus);
                break;
            case 'd':
                sscanf(optarg, "%x", &devfn);
                break;
            case 'f':
                strcpy(fw_name, optarg);
                break;
       }
     }

	if(rr_init(bus, devfn) < 0)
	{
	    fprintf(stderr, "Failed to initialize rawrabbit.\n");
	    return -1;
	}


	dev->writel = spec_writel;
	dev->readl = spec_readl;
	dev->base_addr = 0x80000;

/*    if(rr_load_bitstream_from_file(fw_name) < 0)
    {
        fprintf(stderr,"Failed to load FPGA bitstream.\n");
        return -1;
    }*/

	if(fdelay_init(dev) < 0)
		return -1;

    return 0;
}
