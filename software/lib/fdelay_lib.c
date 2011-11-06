/* 
	FmcDelay1ns4Cha (a.k.a. The Fine Delay Card)
	User-space driver/library
	
	Tomasz Włostowski/BE-CO-HT, 2011
	
	(c) Copyright CERN 2011
	Licensed under LGPL 2.1
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/time.h>
#include <math.h>

#include "fdelay_regs.h"
#include "pll_config.h"
#include "acam_gpx.h"

#include "fdelay_lib.h"
#include "fdelay_private.h"


/* 
----------------------
Some utility functions
---------------------- 
*/

static int extra_debug = 1;

static void dbg(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
 	if(extra_debug)
		vfprintf(stderr,fmt,ap);
	va_end(ap);
}

/* Returns the numer of microsecond timer ticks */
static inline int64_t get_tics()
{
    struct timezone tz= {0,0};
    struct timeval tv;
    gettimeofday(&tv, &tz);
    return (int64_t)tv.tv_sec * 1000000LL + (int64_t) tv.tv_usec;
}

/* Microsecond-accurate delay */
void udelay(uint32_t usecs)
{
  int64_t ts = get_tics();

  while(get_tics() - ts < (int64_t)usecs);
}

/* 
----------------------------------
Simple SPI Master driver
----------------------------------
*/

/* Initializes the SPI Controller */
static void oc_spi_init(fdelay_device_t *dev)
{
	fd_decl_private(dev) 

}

/* Sends (num_bits) from (in) to slave at CS line (ss), storint the readback data in (*out) */
static void oc_spi_txrx(fdelay_device_t *dev, int ss, int num_bits, uint32_t in, uint32_t *out)
{
	fd_decl_private(dev);
    uint32_t scr = 0, r;
 
    scr = FD_SCR_DATA_W(in) | FD_SCR_CPOL;
	if(ss == CS_PLL)
		scr |= FD_SCR_SEL_PLL;
	else if(ss == CS_GPIO)
		scr |= FD_SCR_SEL_GPIO;
	
	fd_writel(scr, FD_REG_SCR);
	fd_writel(scr | FD_SCR_START, FD_REG_SCR);
	while(! (fd_readl(FD_REG_SCR) & FD_SCR_READY));
	scr = fd_readl(FD_REG_SCR);
	r = FD_SCR_DATA_R(scr);
//	if(ss==CS_PLL)
//		printf("IN %x OUT %x\n", in, scr);
	if(out) *out=r;
	udelay(100);

}

/* 
-----------------
AD9516 PLL Driver
-----------------
*/ 

/* Writes an AD9516 register */
static inline void ad9516_write_reg(fdelay_device_t *dev, uint16_t reg, uint8_t val)
{
	oc_spi_txrx(dev, CS_PLL, 24, ((uint32_t)(reg & 0xfff) << 8) | val, NULL);
}

/* Reads a register from AD9516 */
static inline uint8_t ad9516_read_reg(fdelay_device_t *dev, uint16_t reg)
{
	uint32_t rval;
	oc_spi_txrx(dev, CS_PLL, 24, ((uint32_t)(reg & 0xfff) << 8) | (1<<23), &rval);
	printf("ReadReg: %x %x\n", reg, rval);
	return rval & 0xff;
}

/* Initializes the AD9516 PLL by loading a pre-defined register set and waiting until the PLL has locked */
static int ad9516_init(fdelay_device_t *dev)
{
	fd_decl_private(dev)
	int i;
	const int64_t lock_timeout = 10000000LL;
	int64_t start_tics;
	
    dbg("%s: Initializing AD9516 PLL...\n", __FUNCTION__);
	
	ad9516_write_reg(dev, 0, 0x99);
//xit(-1);
	ad9516_write_reg(dev, 0x232, 1);

	/* Check if the chip is present by reading its ID register */
	if(ad9516_read_reg(dev, 0x3) != 0xc3)
	{
	  dbg("%s: AD9516 PLL not responding.\n", __FUNCTION__);
	  return -1;
	}
	
	/* Load the regs */
	for(i=0;ad9516_regs[i].reg >=0 ;i++)
		ad9516_write_reg (dev, ad9516_regs[i].reg, ad9516_regs[i].val);
		
	ad9516_write_reg(dev, 0x232, 1);


	/* Wait until the PLL has locked */

	start_tics = get_tics();
	for(;;)
	{
		if(ad9516_read_reg(dev, 0x1f) & 1)
			break;
		
		if(get_tics() - start_tics > lock_timeout)
		{
			 dbg("%s: AD9516 PLL does not lock.\n", __FUNCTION__);
			 return -1;
		}
		udelay(100);
    }
    
	/* Synchronize the phase of all clock outputs (this is critical for the accuracy!) */
	ad9516_write_reg(dev, 0x230, 1);
	ad9516_write_reg(dev, 0x232, 1);
	ad9516_write_reg(dev, 0x230, 0);
	ad9516_write_reg(dev, 0x232, 1);

    dbg("%s: AD9516 locked.\n", __FUNCTION__);

	return 0;
}

/* 
----------------------------
MCP23S17 SPI I/O Port Driver
----------------------------
*/ 

/* Writes MCP23S17 register */
static inline void mcp_write(fdelay_device_t *dev, uint8_t reg, uint8_t val)
{
	oc_spi_txrx(dev, CS_GPIO, 24, 0x4e0000 | ((uint32_t)reg<<8) | val, NULL);
}

/* Reads MCP23S17 register */
static uint8_t mcp_read(fdelay_device_t *dev, uint8_t reg)
{
	uint32_t rval;
	oc_spi_txrx(dev, CS_GPIO, 24, 0x4f0000 | ((uint32_t)reg<<8), &rval);
	return rval & 0xff;
}

/* Sets the direction (0 = input, non-zero = output) of a particular MCP23S17 GPIO pin */
static void sgpio_set_dir(fdelay_device_t *dev, int pin, int dir)
{
	uint8_t iodir = (MCP_IODIR) + (pin & 0x100 ? 1 : 0);
    uint8_t x;
    
    x = mcp_read(dev, iodir);
    
	if(dir) x &= ~(pin); else x |= (pin);
	
	mcp_write(dev, iodir, x);
}

/* Sets the value on a given MCP23S17 GPIO pin */
static void sgpio_set_pin(fdelay_device_t *dev, int pin, int val)
{
	uint8_t gpio = (MCP_GPIO) + (pin & 0x100 ? 1 : 0);
    uint8_t x;
    
    x = mcp_read(dev, gpio);
	
	if(!val) x &= ~(pin); else x |= (pin);
	mcp_write(dev, gpio, x);
}

/* 
----------------------------------------
ACAM Time To Digital Converter functions
----------------------------------------
*/

/* Writes a particular ACAM register. Works only if (GCR.BYPASS == 1) - i.e. when
   the ACAM is controlled from the host instead of the delay core. */
static void acam_write_reg(fdelay_device_t *dev, uint8_t reg, uint32_t data)
{
	fd_decl_private(dev)

	fd_writel((((uint32_t) (reg)) << 28) | (data & 0xfffffff), FD_REG_TAR);
	udelay(1);
	fd_writel(FD_TDCSR_WRITE, FD_REG_TDCSR);
	udelay(1);
}

/* Reads a register from the ACAM TDC. As for the function above, GCR.BYPASS must be enabled */
static uint32_t acam_read_reg(fdelay_device_t *dev, uint8_t reg)
{
	fd_decl_private(dev)

	fd_writel((((uint32_t) (reg)) << 28), FD_REG_TAR);
	udelay(1);
	fd_writel(FD_TDCSR_READ, FD_REG_TDCSR);
	udelay(1);
	return fd_readl(FD_REG_TAR) & 0xfffffff;
}

/* Calculates the parameters of the ACAM PLL (hsdiv and refdiv) 
   for a given bin size and reference clock frequency. Returns the closest
   achievable bin size. */
static double acam_calc_pll(int *hsdiv, int *refdiv, double bin, double clock_freq)
{
	int h;
	int r;
	double best_err = 100000;
	double best_bin;

/* Try all possible divider settings */
	for(h=1;h<=255;h++)
	for(r=0;r<=7;r++)
	{
	 	double b = ((1.0/clock_freq) * 1e12) * pow(2.0, (double) r) / (216.0 * (double)h);

		if(fabs(bin - b) < best_err)
		{
		 	best_err=fabs(bin-b);
		 	best_bin = b;
		 	*hsdiv=  h;
		 	*refdiv = r;
		}
	}

	dbg("%s: requested bin=%.02fps best=%.02fps error=%.02f%%\n", __FUNCTION__, bin, best_bin, (best_err/bin) * 100.0);
	dbg("%s: hsdiv=%d refdiv=%d\n", __FUNCTION__, *hsdiv, *refdiv);

	return best_bin;
}

/* Returns non-zero if the ACAM's internal PLL is locked */
static inline int acam_pll_locked(fdelay_device_t *dev)
{
	uint32_t r12 = acam_read_reg(dev, 12);
 	return !(r12 & AR12_NotLocked);
}

/* Configures the ACAM TDC to work in a particular mode. Currently there are two modes
   supported: R-Mode for the normal operation (delay/timestamper) and I-Mode for the purpose
   of calibrating the fine delay lines. */
   
static int acam_configure(fdelay_device_t *dev, int mode)
{
	fd_decl_private(dev)
	
	int hsdiv, refdiv;
	int64_t start_tics;
	const int64_t lock_timeout = 2000000LL;

	hw->acam_bin = acam_calc_pll(&hsdiv, &refdiv, 80.9553, 31.25e6) / 3.0;

	/* Disable TDC inputs prior to configuring */
	fd_writel(FD_TDCSR_STOP_DIS | FD_TDCSR_START_DIS, FD_REG_TDCSR);

	if(mode == ACAM_RMODE)
	{
	 	acam_write_reg(dev, 0, AR0_ROsc | AR0_RiseEn0 | AR0_RiseEn1 | AR0_HQSel );
	 	acam_write_reg(dev, 1, AR1_Adj(0, 0) | 
	 					  AR1_Adj(1, 2) | 
	 					  AR1_Adj(2, 6) | 
	 					  AR1_Adj(3, 0) | 
	 					  AR1_Adj(4, 2) | 
	 					  AR1_Adj(5, 6) | 
	 					  AR1_Adj(6, 0));
	   	acam_write_reg(dev, 2, AR2_RMode | AR2_Adj(7, 2) | AR2_Adj(8, 6));
	   	acam_write_reg(dev, 3, 0);
	   	acam_write_reg(dev, 4, AR4_EFlagHiZN);
	   	acam_write_reg(dev, 5, AR5_StartRetrig |AR5_StartOff1(hw->calib.acam_start_offset) | AR5_MasterAluTrig);
	   	acam_write_reg(dev, 6, AR6_Fill(200) | AR6_PowerOnECL);
	   	acam_write_reg(dev, 7, AR7_HSDiv(hsdiv) | AR7_RefClkDiv(refdiv) | AR7_ResAdj | AR7_NegPhase);
	   	acam_write_reg(dev, 11, 0x7ff0000);
	   	acam_write_reg(dev, 12, 0x0000000);
	   	acam_write_reg(dev, 14, 0);
 	
		/* Reset the ACAM after the configuration */
	   	acam_write_reg(dev, 4, AR4_EFlagHiZN | AR4_MasterReset | AR4_StartTimer(0));
	} else if (mode == ACAM_IMODE)
	{
		acam_write_reg(dev, 0, AR0_TRiseEn(0) | AR0_HQSel | AR0_ROsc);
	   	acam_write_reg(dev, 2, AR2_IMode);
	   	acam_write_reg(dev, 5, AR5_StartOff1(3000) | AR5_MasterAluTrig);
	   	acam_write_reg(dev, 6, 0);
	   	acam_write_reg(dev, 7, AR7_HSDiv(hsdiv) | AR7_RefClkDiv(refdiv) | AR7_ResAdj | AR7_NegPhase);
   	   	acam_write_reg(dev, 11, 0x7ff0000);
	   	acam_write_reg(dev, 12, 0x0000000);
	   	acam_write_reg(dev, 14, 0);

		/* Reset the ACAM after the configuration */
		acam_write_reg(dev, 4, AR4_EFlagHiZN | AR4_MasterReset | AR4_StartTimer(0));
	} else         
		return -1;  /* Unsupported mode? */

	dbg("%s: Waiting for ACAM ring oscillator lock...\n", __FUNCTION__);

	start_tics = get_tics();
	for(;;)
	{
		if(acam_pll_locked(dev))
			break;
		
		if(get_tics() - start_tics > lock_timeout)
		{
			 dbg("%s: ACAM PLL does not lock.\n", __FUNCTION__);
			 return -1;
		}
		usleep(10000);
    }

    return 0;
}

/* 
---------------------
Calibration functions
---------------------
*/

/* Measures the the FPGA-generated TDC start and the output of one of the fine delay chips (channel)
   at a pre-defined number of taps (fine). Retuns the delay in picoseconds. The measurement is repeated
   and averaged (n_avgs) times. Also, the standard deviation of the result can be written to (sdev) 
   if it's not NULL. */
   
static double measure_output_delay(fdelay_device_t *dev, int channel, int fine, int n_avgs, double *sdev)
{
	fd_decl_private(dev)

	double acc = 0.0, std = 0.0;
	int i;

/* Mapping between the channel of the delay card and the stop inputs of the ACAM */
	int chan_to_acam[5] = {0, 5, 6, 3, 4}; 

/* Mapping between the channel number and the time tag FIFOs of the ACAM */
	int chan_to_fifo[5] = {0, 9, 9, 8, 8};
	double rec[1024];
	

	/* Enable the stop input in the ACAM corresponding to the channel being calibrated */
	acam_write_reg(dev, 0, AR0_TRiseEn(0) | AR0_TRiseEn(chan_to_acam[channel]) | AR0_HQSel | AR0_ROsc);

    /* Program the output delay line setpoint */
	fd_writel( fine, FD_REG_FRR1  + 0x20 * (channel - 1));
   	fd_writel( FD_DCR1_FORCE_DLY | FD_DCR1_POL, FD_REG_DCR1 + 0x20 * (channel - 1));
   	
   	/* Set the calibration pulse mask to genrate calibration pulses only on one channel at a time.
   	   This minimizes the crosstalk in the output buffer which can severely decrease the accuracy
   	   of calibration measurements */
    fd_writel( FD_CALR_PSEL_W(1<<(channel-1)), FD_REG_CALR);

	udelay(1);
	
	/* Do n_avgs single measurements and average */
	for(i=0;i<n_avgs;i++)
	{
		uint32_t fr;
		/* Re-arm the ACAM (it's working in a single-shot mode) */
		fd_writel( FD_TDCSR_ALUTRIG, FD_REG_TDCSR);
	udelay(1);
		/* Produce a calibration pulse on the TDC start and the appropriate output channel */
        fd_writel( FD_CALR_CAL_PULSE | FD_CALR_PSEL_W((1<<(channel-1))), FD_REG_CALR);
           	udelay(1);
		/* read the tag, convert to picoseconds and average */
		fr = acam_read_reg(dev, chan_to_fifo[channel]);
	 	double tag = (double)((fr >> 0) & 0x1ffff) * hw->acam_bin * 3.0;
	 	acc += tag;
	 	rec[i] = tag;
	}

	/* Calculate standard dev and average value */	
	acc /= (double) n_avgs;
	for(i=0;i<n_avgs;i++)
		std += (rec[i] - acc) * (rec[i] - acc);

	if(sdev) *sdev = sqrt(std /(double) n_avgs);
	
	return acc;
}


/* Measures the transfer function of the fine delay line. Used for testing/debugging purposes. */
static void dbg_transfer_function(fdelay_device_t *dev)
{
	fd_decl_private(dev)

	int channel, i;
	double bias, x, meas[FDELAY_NUM_TAPS][4], sdev[FDELAY_NUM_TAPS][4];	

	fd_writel( FD_GCR_BYPASS, FD_REG_GCR);
	acam_configure(dev, ACAM_IMODE);
	
	fd_writel( FD_TDCSR_START_EN | FD_TDCSR_STOP_EN, FD_REG_TDCSR);

	for(channel = 1; channel <= 4; channel++)
	{
		dbg("calibrating channel %d\n", channel);
		bias = measure_output_delay(dev, channel, 0, FDELAY_CAL_AVG_STEPS, &sdev[0][channel-1]);
		meas[0][channel-1] = 0.0;
		for(i=FDELAY_NUM_TAPS-1;i>=0;i--)
		{	
			x = measure_output_delay(dev, channel, i, 
				FDELAY_CAL_AVG_STEPS, &sdev[i][channel-1]);
			meas[i][channel-1] = x - bias;
		}
	}
		
	FILE *f=fopen("t_func.dat","w");

	for(i=0;i<FDELAY_NUM_TAPS;i++)
	{
	 	fprintf(f, "%d %.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f\n", i, 
	 	meas[i][0], meas[i][1], meas[i][2], meas[i][3],
	 	sdev[i][0], sdev[i][1], sdev[i][2], sdev[i][3]);
	}
	
	fclose(f);
}

/* Finds the preset (i.e. the numer of taps) of the output delay line in (channel) 
   at which it introduces exactly 8 ns more than when it's programmed to 0 taps.
   Uses a binary search algorithm to speed up the calibration (assuming that the 
   line is monotonous). */
   
static int find_8ns_tap(fdelay_device_t *dev, int channel)
{
	int l = 0, r=FDELAY_NUM_TAPS-1;

/* Measure the delay at zero setting, so it can be further subtracted to get only the 
   delay part introduced by the delay line (ingoring the TDC, FPGA and routing delays). */
	double bias = measure_output_delay(dev, channel, 0, FDELAY_CAL_AVG_STEPS, NULL);

	while(abs(l-r)>1)
	{
		int mid = (l+r) / 2;
	 	double dly = measure_output_delay(dev, channel, mid, FDELAY_CAL_AVG_STEPS, NULL) - bias;
	 	
	 	if(dly < 8000.0) l = mid; else r = mid;
	}
	
	return l;
}

/* Performs the startup calibration of the output delay lines. */
void calibrate_outputs(fdelay_device_t *dev)
{
	fd_decl_private(dev)
	int i, channel;

//	dbg_transfer_function(dev);
	fd_writel( FD_GCR_BYPASS, FD_REG_GCR);
	acam_configure(dev, ACAM_IMODE);
	fd_writel( FD_TDCSR_START_EN | FD_TDCSR_STOP_EN, FD_REG_TDCSR);

	for(channel = 1; channel <= 4; channel++)
	{
		int cal_val = find_8ns_tap(dev, channel);
     	dbg("%s: CH%d: 8ns @ %d\n", __FUNCTION__, channel, cal_val);
     	hw->frr[channel-1] = cal_val;
	}
}


#if 0
void poll_stats()
{
    int raw = fd_readl(FD_REG_IECRAW);
    int tagged  = fd_readl(FD_REG_IECTAG);
    int pd  = fd_readl(FD_REG_IEPD) & 0xff;

    if(events_raw != raw || events_tagged != tagged || pd != tag_delay)
    {
        events_raw = raw;
        events_tagged = tagged;
        tag_delay = pd;
//	if(events_raw != events_tagged) printf("ERROR: raw %d vs tagged %d\n", raw,tagged);
//        printf("NewStats: raw %d tagged %d pdelay %d nsec\n", raw, tagged ,(pd+3)*8);
    }

}
#endif

static int read_calibration_eeprom(fdelay_device_t *dev, struct fine_delay_calibration *d_cal)
{
 	struct fine_delay_calibration cal;
 	
 	mi2c_init(dev);
 	
 	if(eeprom_read(dev, EEPROM_ADDR, 0, (uint8_t *) &cal, sizeof(struct fine_delay_calibration)) != sizeof(struct fine_delay_calibration))
 		return -1;
 	
	if(cal.magic != FDELAY_MAGIC_ID)
		return -1;
	
	memcpy(d_cal, &cal, sizeof(cal));
	return 0;
}

/*
-------------------------------------
             Public API
-------------------------------------
*/

/* Initialize & self-calibrate the Fine Delay card */
int fdelay_init(fdelay_device_t *dev)
{
	struct fine_delay_hw *hw;
	
	dbg("Init: dev %x\n", dev);
	hw = (struct fine_delay_hw *) malloc(sizeof(struct fine_delay_hw));
	if(! hw)
		return -1;

	dev->priv_fd = (void *) hw;
	
	hw->base_addr = dev->base_addr;	
 	hw->base_i2c = 0x100;
 	hw->base_onewire = 0x200;
 	hw->wr_enabled = 0;
 	hw->wr_state = FDELAY_FREE_RUNNING;


	dbg("%s: Initializing the Fine Delay Card\n", __FUNCTION__);
	
	/* Read the Identification register and check if we are talking to a proper Fine Delay HDL Core */
	if(fd_readl(FD_REG_IDR) != FDELAY_MAGIC_ID)
	{
	 	dbg("%s: invalid core signature. Are you sure you have loaded the FPGA with the Fine Delay firmware?\n", __FUNCTION__);
	 	return -1;
	}

	//if(read_calibration_eeprom(dev, &hw->calib) < 0)
	{
		int i;
		dbg("%s: Calibration EEPROM not found or unreadable. Using default calibration values\n", __FUNCTION__);

		hw->calib.tdc_zero_offset = 35600;
		hw->calib.atmcr_val =  1 | (2000 << 4);
		hw->calib.adsfr_val = 56648;
		hw->calib.acam_start_offset = 10000;
     	for(i=0;i<4;i++)
     		hw->calib.zero_offset[i] = 50000;
	}
	
//	exit(-1);


	/* Initialize the clock system - AD9516 PLL */	
	oc_spi_init(dev);

	if(ad9516_init(dev) < 0)
		return -1;

	/* Configure default states of the SPI GPIO pins */
	sgpio_set_dir(dev, SGPIO_LED_TERM, 1);
	sgpio_set_pin(dev, SGPIO_LED_TERM, 0);
	sgpio_set_dir(dev, SGPIO_TRIG_SEL, 1);
	sgpio_set_pin(dev, SGPIO_TRIG_SEL, 1);
	sgpio_set_dir(dev, SGPIO_DRV_OEN, 1);
	sgpio_set_pin(dev, SGPIO_DRV_OEN, 1);
	sgpio_set_dir(dev, SGPIO_TERM_EN, 1);
	sgpio_set_pin(dev, SGPIO_TERM_EN, 0);

	/* Reset the FD core once we have proper reference/TDC clocks */
	fd_writel( 0xdeadbeef, FD_REG_RSTR);

	/* Disable the delay generator core, so we can access the ACAM from the host, both for 
	   initialization and calibration */
	fd_writel( FD_GCR_BYPASS, FD_REG_GCR);
	
	/* Calibrate the output delay lines */
//	calibrate_outputs(dev);

	/* Switch to the R-MODE (more precise) */
	acam_configure(dev, ACAM_RMODE);

	/* Switch the ACAM to be driven by the delay core instead of the host */
	fd_writel( 0, FD_REG_GCR);

	/* Clear and disable the timestamp readout buffer */
	fd_writel( FD_TSBCR_PURGE | FD_TSBCR_RST_SEQ, FD_REG_TSBCR);
	
	/* Program the ACAM-specific timestamper registers using pre-defined calibration values:
	   - bin -> internal timebase scalefactor (ADSFR),
	   - Start offset (must be consistent with the value written to the ACAM reg 4)
	   - timestamp merging control register (ATMCR) */
	fd_writel( hw->calib.adsfr_val, FD_REG_ADSFR);
	fd_writel( 3 * hw->calib.acam_start_offset, FD_REG_ASOR);
	fd_writel( hw->calib.atmcr_val, FD_REG_ATMCR);

	/* Synchronize the internal time base - for the time being to itself (i.e. ensure that
	   all the time counters inside the FD Core are in sync */
	fd_writel(FD_GCR_CSYNC_INT, FD_REG_GCR);

	/* Enable input */	
	udelay(1);
	fd_writel(FD_GCR_INPUT_EN, FD_REG_GCR);

	/* Enable output driver */
	sgpio_set_pin(dev, SGPIO_DRV_OEN, 1);

	dbg("FD initialized\n");
	return 0;
}

/* Configures the trigger input. Enable enables the input, termination selects the impedance
   of the trigger input (0 == 2kohm, 1 = 50 ohm) */
int fdelay_configure_trigger(fdelay_device_t *dev, int enable, int termination)
{
	if(termination)
	{
		dbg("%s: 50-ohm terminated mode\n", __FUNCTION__);
		  sgpio_set_pin(dev,SGPIO_LED_TERM,1);
		  sgpio_set_pin(dev,SGPIO_TERM_EN,1);
	} else {
			dbg("%s: high impedance mode\n", __FUNCTION__);
		  sgpio_set_pin(dev,SGPIO_LED_TERM,0);
		  sgpio_set_pin(dev,SGPIO_TERM_EN,0);

	};

	if(enable)
	{
//		fd_writel(FD_GCR_BYPASS, FD_REG_GCR);
//		dbg("EF %d\n", fd_readl(FD_REG_TDCSR) & FD_TDCSR_EMPTY ?  1: 0);
//		fd_writel(0, FD_REG_GCR);
		fd_writel(fd_readl(FD_REG_GCR) | FD_GCR_INPUT_EN, FD_REG_GCR);
	} else	
		fd_writel(fd_readl(FD_REG_GCR) & (~FD_GCR_INPUT_EN) , FD_REG_GCR);

	return 0;
}

/* Converts a positive time interval expressed in picoseconds to the timestamp format used in the Fine Delay core */
/*fdelay_time_t fdelay_from_picos(const uint64_t ps)
{
	fdelay_time_t t;
	int64_t rescaled;
	
	rescaled = (int64_t) ((long double) ps * (long double)4096 / (long double)8000);
	
	t.frac = rescaled % 4096;
	rescaled -= t.frac;
	rescaled /= 4096;
	t.coarse = rescaled % 125000000ULL;
	rescaled -= t.coarse;
	rescaled /= 125000000ULL;
	t.utc = rescaled;
	
	dbg("fdelay_from_picos: %d:%d:%d\n", t.utc, t.coarse, t.frac);
	return t;
}*/

fdelay_time_t fdelay_from_picos(const uint64_t ps)
{
	fdelay_time_t t;
	uint64_t tmp = ps;
//	int64_t rescaled;
	
//	rescaled = (int64_t) ((long double) ps * (long double)4096 / (long double)8000);
	
	t.frac = (tmp % 8000ULL) * 4096ULL / 8000ULL;
	tmp -= (tmp % 8000ULL);
	tmp /= 8000ULL;
	t.coarse = tmp % 125000000ULL;
	tmp -= (tmp % 125000000ULL);
	tmp /= 125000000ULL;
	t.utc = tmp;
	
	dbg("fdelay_from_picos: %d:%d:%d\n", t.utc, t.coarse, t.frac);
	return t;
}

/* Substract two timestamps */
static fdelay_time_t ts_sub(fdelay_time_t a, fdelay_time_t b)
{
 	a.frac -= b.frac;
 	if(a.frac < 0)
 	{
 	 	a.frac += 4096;
 	 	a.coarse--;
 	}
 	a.coarse -= b.coarse;
 	if(a.coarse < 0)
 	{
 	 	a.coarse += 125000000;
 	 	a.utc ++;
 	}
 	return a;
}

/* Converts a Fine Delay time stamp to plain picoseconds */
int64_t fdelay_to_picos(const fdelay_time_t t)
{
	int64_t tp = (((int64_t)t.frac * 8000LL) >> 12) + ((int64_t) t.coarse * 8000LL) + ((int64_t)t.utc * 1000000000000LL);
	return tp;
}

static int poll_rbuf(fdelay_device_t *dev)
{
 	if((fd_readl(FD_REG_TSBCR) & FD_TSBCR_EMPTY) == 0)
		return 1;
	return 0;
}

int fdelay_configure_readout(fdelay_device_t *dev, int enable)
{
	if(enable)
	{
		fd_writel( FD_TSBCR_PURGE | FD_TSBCR_RST_SEQ, FD_REG_TSBCR);
		fd_writel( FD_TSBCR_ENABLE, FD_REG_TSBCR);
    } else
		fd_writel( FD_TSBCR_PURGE | FD_TSBCR_RST_SEQ, FD_REG_TSBCR);

	return 0;
}

/* Reads up to (how_many) timestamps from the FD ring buffer and stores them in (timestamps). 
   Returns the number of read timestamps. */
int fdelay_read(fdelay_device_t *dev, fdelay_time_t *timestamps, int how_many)
{
	fd_decl_private(dev)

	int n_read = 0;
	
	while(poll_rbuf(dev))
	{
		fdelay_time_t ts;
		uint32_t seq_frac;
		if(!how_many) break;
		
		ts.utc = fd_readl(FD_REG_TSBR_U);
		ts.coarse = fd_readl(FD_REG_TSBR_C) & 0xfffffff;
		seq_frac =  fd_readl(FD_REG_TSBR_FID);
		ts.frac = seq_frac & 0xfff;
		ts.seq_id = seq_frac >> 16;
		*timestamps++ = ts_sub(ts, fdelay_from_picos(hw->calib.tdc_zero_offset));
		
		how_many--;
		n_read++;
	}
//	printf("read %d\n", how_many, n_read);

	return n_read;
}

/* Configures the output channel (channel) to produce pulses delayed from the trigger by (delay_ps).
   The output pulse width is proviced in (width_ps) parameter. */
int fdelay_configure_output(fdelay_device_t *dev, int channel, int enable, int64_t delay_ps, int64_t width_ps)
{
	fd_decl_private(dev)
 	uint32_t base = (channel-1) * 0x20;
 	uint32_t dcr;
 	fdelay_time_t start, end;
 	
 	if(channel < 1 || channel > 4)
 		return -1;
 	
 	delay_ps -= hw->calib.zero_offset[channel-1];
 	start = fdelay_from_picos(delay_ps);
 	end = fdelay_from_picos(delay_ps + width_ps);
 	
	
 	fd_writel(hw->frr[channel-1], base + FD_REG_FRR1);
 	fd_writel(start.utc, base + FD_REG_U_START1);
 	fd_writel(start.coarse, base + FD_REG_C_START1);
 	fd_writel(start.frac, base + FD_REG_F_START1);
 	fd_writel(end.utc, base + FD_REG_U_END1);
 	fd_writel(end.coarse, base + FD_REG_C_END1);
 	fd_writel(end.frac, base + FD_REG_F_END1);
 	
 	dcr = (enable ? FD_DCR1_ENABLE : 0)
 		| FD_DCR1_POL
 		| FD_DCR1_UPDATE;
 		
 	fd_writel(dcr, base + FD_REG_DCR1);
 	return 0;
}

int fdelay_configure_sync(fdelay_device_t *dev, int mode)
{
	fd_decl_private(dev)

	if(mode == FDELAY_SYNC_LOCAL)
	{
	 	fd_writel(0, FD_REG_GCR);
	 	fd_writel(FD_GCR_CSYNC_INT, FD_REG_GCR);
	 	hw->wr_enabled = 0;
	} else {
	 	fd_writel(0, FD_REG_GCR);
	 	hw->wr_enabled = 1;
	 	hw->wr_state = FDELAY_WR_OFFLINE;
	}
}

int fdelay_get_sync_status(fdelay_device_t *dev)
{
	fd_decl_private(dev)

	if(!hw->wr_enabled) return FDELAY_FREE_RUNNING;
	
	switch(hw->wr_state)
	{
	 	case FDELAY_WR_OFFLINE: 
	 		if(fd_readl(FD_REG_GCR) & FD_GCR_WR_READY)
	 			{
	 			 	dbg("-> WR Core synced\n");
	 			 	hw->wr_state = FDELAY_WR_READY;
	 			}
 			break;
 		
 		case FDELAY_WR_READY:
 		 	fd_writel(FD_GCR_WR_LOCK_EN, FD_REG_GCR);
 		 	hw->wr_state = FDELAY_WR_SYNCING;
 		  	break;

 		case FDELAY_WR_SYNCING:
 			if(fd_readl(FD_REG_GCR) & FD_GCR_WR_LOCKED)
 			{
	 			fd_writel(FD_GCR_WR_LOCK_EN | FD_GCR_CSYNC_WR, FD_REG_GCR);
	 			fd_writel(FD_GCR_WR_LOCK_EN , FD_REG_GCR);
	 			fd_writel(FD_GCR_WR_LOCK_EN | FD_GCR_INPUT_EN, FD_REG_GCR);
 			
				hw->wr_state = FDELAY_WR_SYNCED;
			}
 			break;
 			
 		case FDELAY_WR_SYNCED:
 			if((fd_readl(FD_REG_GCR) & FD_GCR_WR_LOCKED) == 0)
 				hw->wr_state = FDELAY_WR_OFFLINE;
 			break;
	}

	return hw->wr_state;
}

