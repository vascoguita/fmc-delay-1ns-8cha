#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/time.h>

#include <rawrabbit.h>
#include "rr_io.h"

#define DEVNAME "/dev/rawrabbit"

static int fd;

int rr_bind(int a_fd)
{
        fd = a_fd;
        return 0;
}

int rr_init(int bus, int devfn)
{
	struct rr_devsel devsel;

	int ret = -EINVAL;

    devsel.bus = bus;
    devsel.devfn = devfn;
    devsel.subvendor = RR_DEVSEL_UNUSED;
    devsel.vendor = 0x10dc;//RR_DEVSEL_UNUSED;
    devsel.device = 0x18d; //RR_DEVSEL_UNUSED;
    devsel.subdevice = RR_DEVSEL_UNUSED;
    
    
	fd = open(DEVNAME, O_RDWR);
	if (fd < 0) {
		return -1;
	}
	
	if (ioctl(fd, RR_DEVSEL, &devsel) < 0) {
        return -EIO;
	}

	return 0;
}

int rr_writel(uint32_t data, uint32_t addr)
{
	struct rr_iocmd iocmd;
	iocmd.datasize = 4;
	iocmd.address = addr;
	iocmd.address |= __RR_SET_BAR(0);
	iocmd.data32 = data;
	ioctl(fd, RR_WRITE, &iocmd);
}

uint32_t rr_readl(uint32_t addr)
{
	struct rr_iocmd iocmd;
	iocmd.datasize = 4;
	iocmd.address = addr;
	iocmd.address |= __RR_SET_BAR(0);
	ioctl(fd, RR_READ, &iocmd);
	return iocmd.data32;
}

static void gennum_writel(uint32_t data, uint32_t addr)
{
	struct rr_iocmd iocmd;
	iocmd.datasize = 4;
	iocmd.address = addr;
	iocmd.address |= __RR_SET_BAR(4);
	iocmd.data32 = data;
	ioctl(fd, RR_WRITE, &iocmd);
}

static uint32_t gennum_readl(uint32_t addr)
{
	struct rr_iocmd iocmd;
	iocmd.datasize = 4;
	iocmd.address = addr;
	iocmd.address |= __RR_SET_BAR(4);
	ioctl(fd, RR_READ, &iocmd);
	return iocmd.data32;
}

static inline int64_t get_tics()
{
    struct timezone tz= {0,0};
    struct timeval tv;
    gettimeofday(&tv, &tz);
    return (int64_t)tv.tv_sec * 1000000LL + (int64_t) tv.tv_usec;
}

/* These must be set to choose the FPGA configuration mode */
#define GPIO_BOOTSEL0 15
#define GPIO_BOOTSEL1 14

static inline uint8_t reverse_bits8(uint8_t x)
{
	x = ((x >> 1) & 0x55) | ((x & 0x55) << 1);
	x = ((x >> 2) & 0x33) | ((x & 0x33) << 2);
	x = ((x >> 4) & 0x0f) | ((x & 0x0f) << 4);

	return x;
}

static uint32_t unaligned_bitswap_le32(const uint32_t *ptr32)
{
	static uint32_t tmp32;
	static uint8_t *tmp8 = (uint8_t *) &tmp32;
	static uint8_t *ptr8;

	ptr8 = (uint8_t *) ptr32;

	*(tmp8 + 0) = reverse_bits8(*(ptr8 + 0));
	*(tmp8 + 1) = reverse_bits8(*(ptr8 + 1));
	*(tmp8 + 2) = reverse_bits8(*(ptr8 + 2));
	*(tmp8 + 3) = reverse_bits8(*(ptr8 + 3));

	return tmp32;
}

static inline void gpio_out(int fd, const uint32_t addr, const int bit, const int value)
{
	uint32_t reg;

	reg = gennum_readl(addr);

	if(value)
		reg |= (1<<bit);
	else
		reg &= ~(1<<bit);

    gennum_writel(reg, addr);
}

/*
 * Unfortunately, most of the following is from fcl_gn4124.cpp, for which
 * the license terms are at best ambiguous. 
 */

int loader_low_level(int fd,  const void *data, int size8)
{
	int size32 = (size8 + 3) >> 2;
	const uint32_t *data32 = data;
	int ctrl = 0, i, done = 0, wrote = 0;


	/* configure Gennum GPIO to select GN4124->FPGA configuration mode */
	gpio_out(fd, GNGPIO_DIRECTION_MODE, GPIO_BOOTSEL0, 0);
	gpio_out(fd, GNGPIO_DIRECTION_MODE, GPIO_BOOTSEL1, 0);
	gpio_out(fd, GNGPIO_OUTPUT_ENABLE, GPIO_BOOTSEL0, 1);
	gpio_out(fd, GNGPIO_OUTPUT_ENABLE, GPIO_BOOTSEL1, 1);
	gpio_out(fd, GNGPIO_OUTPUT_VALUE, GPIO_BOOTSEL0, 1);
	gpio_out(fd, GNGPIO_OUTPUT_VALUE, GPIO_BOOTSEL1, 0);


	gennum_writel( 0x00, FCL_CLK_DIV);
	gennum_writel( 0x40, FCL_CTRL); /* Reset */
	i = gennum_readl( FCL_CTRL);
	if (i != 0x40) {
		printf("%s: %i: error\n", __func__, __LINE__);
		return -EIO;
	}
	gennum_writel( 0x00, FCL_CTRL);

	gennum_writel( 0x00, FCL_IRQ); /* clear pending irq */

	switch(size8 & 3) {
	case 3: ctrl = 0x116; break;
	case 2: ctrl = 0x126; break;
	case 1: ctrl = 0x136; break;
	case 0: ctrl = 0x106; break;
	}
	gennum_writel( ctrl, FCL_CTRL);

	gennum_writel( 0x00, FCL_CLK_DIV); /* again? maybe 1 or 2? */

	gennum_writel( 0x00, FCL_TIMER_CTRL); /* "disable FCL timr fun" */

	gennum_writel( 0x10, FCL_TIMER_0); /* "pulse width" */
	gennum_writel( 0x00, FCL_TIMER_1);

	/*
	 * Set delay before data and clock is applied by FCL
	 * after SPRI_STATUS is	detected being assert.
	 */
	gennum_writel( 0x08, FCL_TIMER2_0); /* "delay before data/clk" */
	gennum_writel( 0x00, FCL_TIMER2_1);
	gennum_writel( 0x17, FCL_EN); /* "output enable" */

	ctrl |= 0x01; /* "start FSM configuration" */
	gennum_writel( ctrl, FCL_CTRL);

	while(size32 > 0)
	{
		/* Check to see if FPGA configuation has error */
		i = gennum_readl( FCL_IRQ);
		if ( (i & 8) && wrote) {
			done = 1;
			printf("%s: %i: done after %i\n", __func__, __LINE__,
				wrote);
		} else if ( (i & 0x4) && !done) {
			printf("%s: %i: error after %i\n", __func__, __LINE__,
				wrote);
			return -EIO;
		}

		/* Wait until at least 1/2 of the fifo is empty */
		while (gennum_readl( FCL_IRQ)  & (1<<5))
			;

		/* Write a few dwords into FIFO at a time. */
		for (i = 0; size32 && i < 32; i++) {
			gennum_writel( unaligned_bitswap_le32(data32),
				  FCL_FIFO);
			data32++; size32--; wrote++;
		}
	}

	gennum_writel( 0x186, FCL_CTRL); /* "last data written" */

	/* Checking for the "interrupt" condition is left to the caller */
	return wrote;
}

int rr_load_bitstream_from_file(const char *file_name)
{
    uint8_t *buf;
    FILE *f;
    uint32_t size;
    
    f=fopen(file_name,"rb");
    if(!f) return -1;
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    buf = malloc(size);
    if(!buf)
    {
        fclose(f);
        return -1;
    }
    fseek(f, 0, SEEK_SET);
    fread(buf, 1, size, f);
    fclose(f);
    int rval = loader_low_level(0, buf, size);
    free(buf);
    return rval;
}

