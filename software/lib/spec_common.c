#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "fdelay_lib.h"

void spec_writel(void *priv, uint32_t data, uint32_t addr)
{
	*(volatile uint32_t *)(priv + addr) = data;	
}

uint32_t spec_readl(void *priv, uint32_t addr)
{
	return *(volatile uint32_t *)(priv + addr);
}


void *map_spec(int bus, int dev)
{
    char path[1024];
    int fd;
    void *ptr;
    uint64_t base;
    
    snprintf(path, sizeof(path), "/sys/bus/pci/drivers/spec/0000:%02x:%02x.0/resource", bus, dev);
	FILE *f = fopen(path, "r");
	fscanf(f, "0x%llx", &base);
	printf("raw base addr: %llx\n", base);
    
    fd = open("/dev/mem", O_SYNC | O_RDWR);
    if(fd <= 0)
    {
    	perror("open");
		return NULL;
    }
    ptr = mmap(NULL, 0x100000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, (void*)base);
    
    if((int)ptr == -1)
    {
    	perror("mmap");
	close(fd);
	return NULL;
    }

    return ptr;
}



int spec_fdelay_init(fdelay_device_t *dev, int pbus, int pdev)
{
	dev->priv_io = map_spec(pbus, pdev);

	if(!dev->priv_io)
	{
	 	fprintf(stderr,"Can't map the SPEC @ %x:%x\n", pbus, pdev);
	 	return -1;
	}

	dev->writel = spec_writel;
	dev->readl = spec_readl;
	dev->base_addr = 0x80000;

	if(fdelay_init(dev) < 0)
		return -1;

    return 0;
}
