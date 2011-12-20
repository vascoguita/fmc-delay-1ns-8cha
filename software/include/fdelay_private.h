/* 
	FmcDelay1ns4Cha (a.k.a. The Fine Delay Card)
	User-space driver/library
	
	Private includes
	
	Tomasz Włostowski/BE-CO-HT, 2011
	
	(c) Copyright CERN 2011
	Licensed under LGPL 2.1
*/

#ifndef __FDELAY_PRIVATE_H
#define __FDELAY_PRIVATE_H

#include <stdint.h>

/* SPI Bus chip selects */
#define CS_PLL 1  /* AD9516 PLL */
#define CS_GPIO 2 /* MCP23S17 GPIO */

/* MCP23S17 GPIO expander pin locations: bit 8 = select bank 2, bits 7..0 = mask of the pin in the selected bank */
#define SGPIO_TERM_EN  (1<<0)	 	/* Input termination enable (1 = on) */
#define SGPIO_OUTPUT_EN(x) (1<<(6-x))		/* Output driver enable (1 = on) */
#define SGPIO_TRIG_SEL  (1<<3)  	/* TDC trigger select (0 = trigger input, 1 = FPGA) */
#define SGPIO_CAL_EN  (1<<3)  	/* Calibration mode enable (0 = on) */

/* ACAM TDC operation modes */
#define ACAM_RMODE 0
#define ACAM_IMODE 1

/* MCP23S17 register addresses (only ones which are used by the lib) */
#define MCP_IODIR 0x0
#define MCP_GPIO 0x12
#define MCP_IOCON 0x0a

/* Number of fractional bits in the timestamps/time definitions. Must be consistent with the HDL bitstream.  */
#define FDELAY_FRAC_BITS 12

/* Fractional bits shifted away when converting the fine (< 8ns) part to fit the range of SY89295 delay line. */
#define FDELAY_SCALER_SHIFT 12

/* Number of delay line taps */
#define FDELAY_NUM_TAPS 1024

/* How many times each calibration measurement will be averaged */
#define FDELAY_CAL_AVG_STEPS 1024

/* Fine Delay Card Magic ID */
#define FDELAY_MAGIC_ID 0xf19ede1a

/* RSTR Register value which triggers a reset of the FD Core */
#define FDELAY_RSTR_TRIGGER 0xdeadbeef

/* Calibration eeprom I2C address */
#define EEPROM_ADDR 0x50

/* ACAM Calibration parameters */
struct fine_delay_calibration {
	uint32_t magic;				/* magic ID: 0xf19ede1a */
	uint32_t zero_offset[4]; 	/* Output zero offset, in nsec << FDELAY_FRAC_BITS */
	uint32_t adsfr_val; 		/* ADSFR register value */
	uint32_t acam_start_offset; /* ACAM Start offset value */
	uint32_t atmcr_val; 		/* ATMCR register value */
	int32_t dly_tempco[4]; 		/* SY89295 delay/temperature coefficient in ps/degC << FDELAY_FRAC_BITS */
	int32_t zero_tempco[4];     /* Zero offset/temperature coefficient in ps/degC << FDELAY_FRAC_BITS */
	int32_t cal_temp;			/* Calibration temperature in 0.1 degC */
	uint32_t tdc_zero_offset;   /* Zero offset of the TDC, in picoseconds */
} __attribute__((packed));

/* Internal state of the fine delay card */
struct fine_delay_hw
{
	uint32_t base_addr; 		/* Base address of the core */
	uint32_t base_onewire; 		/* Base address of the core */
	uint32_t base_i2c;			/* SPI Controller offset */
	double acam_bin; 			/* bin size of the ACAM TDC - calculated for */
	uint32_t frr[4];			/* Fine range register for each output, determi*/
	int32_t board_temp;			/* Current temperature of the board in 0.1 degC */
	int wr_enabled;
	int wr_state;
	struct fine_delay_calibration calib;
};

/* some useful access/declaration macros */
#define fd_writel(data, addr) dev->writel(dev->priv_io, data, (dev->base_addr + (addr)))
#define fd_readl(addr) dev->readl(dev->priv_io, (dev->base_addr + (addr)))
#define fd_decl_private(dev) struct fine_delay_hw *hw = (struct fine_delay_hw *) dev->priv_fd;



#endif
