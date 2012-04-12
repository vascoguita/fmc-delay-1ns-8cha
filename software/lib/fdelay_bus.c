/* 
	FmcDelay1ns4Cha (a.k.a. The Fine Delay Card)
	User-space driver/library - bus API creation functions
	
	Tomasz Włostowski/BE-CO-HT, 2011
	
	(c) Copyright CERN 2011
	Licensed under LGPL 2.1
*/
#include <stdio.h>
#include <stdlib.h>

#include "rr_io.h"
#include "minibone_lib.h"
#include "fdelay_lib.h"

static void my_rr_writel(void *priv, uint32_t data, uint32_t addr)
{
rr_writel(data, addr);
}
 
static uint32_t my_rr_readl(void *priv, uint32_t addr)
{
uint32_t d = rr_readl(addr);
return d;
}

static void my_mb_writel(void *priv, uint32_t data, uint32_t addr)
{
	mbn_writel(priv, data, addr >> 2);
}
 
static uint32_t my_mb_readl(void *priv, uint32_t addr)
{
uint32_t d = mbn_readl(priv, addr >> 2);
return d;
}

fdelay_device_t *fdelay_create_rawrabbit(uint32_t base_addr)
{
	fdelay_device_t *dev = malloc(sizeof(fdelay_device_t));
 	rr_init(RR_DEVSEL_UNUSED, RR_DEVSEL_UNUSED);
 	dev->writel = my_rr_writel;
 	dev->readl = my_rr_readl;
 	dev->base_addr = base_addr;
 	return dev;

}

fdelay_device_t *fdelay_create_minibone(char *iface, char *mac_addr, uint32_t base_addr)
{
	void *handle;
	uint8_t target_mac[6];
	fdelay_device_t *dev = malloc(sizeof(fdelay_device_t));
	sscanf(mac_addr, "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &target_mac[0], &target_mac[1], &target_mac[2], &target_mac[3], &target_mac[4], &target_mac[5]);

	handle = mbn_open(iface, target_mac);
	if(handle == NULL)
		return NULL;

//	dbg("%s: remote @ %s [%02x:%02x:%02x:%02x:%02x:%02x], base 0x%08x\n",__FUNCTION__, iface, 
//	target_mac[0], target_mac[1], target_mac[2], target_mac[3], target_mac[4], target_mac[5], base_addr);
		
 	dev->writel = my_mb_writel;
 	dev->readl = my_mb_readl;
 	dev->base_addr = base_addr;
 	dev->priv_io = handle;
 	return dev;

}
