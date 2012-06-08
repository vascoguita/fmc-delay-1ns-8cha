/*
	FmcDelay1ns4Cha (a.k.a. The Fine Delay Card)
	DMTD insertion delay calibration stuff

	Short explaination:
	
	We feed the input of the card with a perioid sequence of pulses, of a frequency, say,
	1 MHz. The card is programmed to introduce a delay of Td. Then, we sample both the input
	and the output of the card with a clock that is slightly offset in frequency wrs to the one that
	was used to generate the pulses - in our case it's (1 + 1/16384) * 1 MHz. The resulting waveforms
	are of very low frequency, but keep the phase shift of the original signals, scaled by a factor of 16384.
	This way we can easily measure the actual insertion delay of the FD and apply a correction factor
	for fdelay_configure_output().

	Tomasz Włostowski/BE-CO-HT, 2012

	(c) Copyright CERN 2012
	Licensed under LGPL 2.1
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <math.h>

#include "fd_channel_regs.h"
#include "fd_main_regs.h"

#include "fdelay_lib.h"
#include "fdelay_private.h"


extern void dbg(const char *fmt, ...);
extern int64_t get_tics();
extern void udelay(uint32_t usecs);

/* WR core shell communication functions */

/* Waits for a WR Core and returns the output of the previous command in rv */ 
static void wait_prompt(fdelay_device_t *dev, char *rv)
{
	char buf[16384],c;
	int pos = 0;

	
	memset(buf, 0, sizeof(buf));
	
	while(pos < sizeof(buf))
	{
		if(spec_vuart_rx(dev->priv_io, &c, 1) == 1)
		{
			buf[pos++] = c;
			
			if(pos >= 5 && !strcmp(buf + pos - 5, "wrc# "))
			{
				int old_pos;
			 	if(!rv)
			 		return;

			 	while(pos>0) if(buf[pos]=='\n'||buf[pos]=='\r')
			 		break;
			 	else
			 		pos--;
			 		
			 	pos-=2;
				old_pos = pos;

			 	while(pos>0) if(buf[pos]=='\n'||buf[pos]=='\r')
			 		break;
			 	else
			 		pos--;

		 		strncpy(rv, buf+pos+1, old_pos - pos);
		 		rv[old_pos-pos]=0;
			 	return;
			}
		}      
	}
	
	dbg("Failure: shell buffer overflow.\n");
	exit(1);
}

/* executes a shell command on the associated WR core */
static int wrc_shell_exec(fdelay_device_t *dev, const char *cmd, char *retval)
{
  	char c;

	while(spec_vuart_rx(dev->priv_io, &c, 1) == 1);

	spec_vuart_tx(dev->priv_io, (char *)cmd, strlen(cmd));
	spec_vuart_tx(dev->priv_io, "\r", 1);
	
	wait_prompt(dev, retval);

	if(retval)
	 	dbg("wr_core exec '%s', retval: '%s'\n", cmd, retval);
	
	return 0;
}

#define DMTD_N_AVGS 10 				/* number of average samples */
#define DELAY_SETPOINT 500000		/* test delay value */

#define DMTD_PULSE_PERIOD 144
#define DMTD_OUTPUT_PERIOD (16384 * DMTD_PULSE_PERIOD / 2) /* period of the DDMTD output signal in 62.5 MHz clock cycles */

struct dmtd_channel {
 	int64_t base;
 	int64_t prev_tag, phase;
 	int64_t period;
 	
};

#define TAG_BITS 23

static void init_dmtd(struct dmtd_channel *ch, int64_t period)
{
	ch->period = period;
	ch->prev_tag = -1;
	ch->base = 0;
}

static int read_dmtd(fdelay_device_t *dev, struct dmtd_channel *ch, int is_out)
{
	fd_decl_private(dev)

	uint32_t addr = (is_out ? FD_REG_DMTR_IN : FD_REG_DMTR_OUT);
	uint32_t value = fd_readl(addr);

	if(value & FD_DMTR_IN_RDY)
	{
		int64_t tag = (int64_t) (value & ((1<<TAG_BITS) - 1)) + ch->base;
		
		if(ch->prev_tag >= 0 && tag < ch->prev_tag) /* DMTD tag counter has 23 bits. We need to unwrap it */
		{
			ch->base += (1LL<<TAG_BITS);
			tag += (1LL<<TAG_BITS);
		}
			
		int64_t epoch = (tag / DMTD_OUTPUT_PERIOD) * DMTD_OUTPUT_PERIOD; /* calculate the offset between the beginning of DDMTD cycle and the current tag */
		ch->phase = tag - epoch;
		ch->prev_tag = tag;
		
		return 1;
	}
	return 0;
}

void calibrate_channel(fdelay_device_t *dev, int channel, double *mean, double *std)
{
	int64_t samples_in[DMTD_N_AVGS], samples_out[DMTD_N_AVGS], delta[DMTD_N_AVGS];
	struct dmtd_channel ch_in, ch_out;
	
	int i, n_in = 0, n_out = 0;
	
	fd_decl_private(dev)

	fdelay_configure_trigger(dev, 0, 0);
	fd_writel(FD_CALR_PSEL_W(0), FD_REG_CALR);

	/* Configure the output to introduce DELAY_SETPOINT delay (but with fixed offset set to 0)*/\
	hw->calib.zero_offset[channel-1] = 0;

	fdelay_configure_output(dev, channel, 1, (int64_t)DELAY_SETPOINT, 200000LL, 0LL, 1);

	/* Disable ALL outputs to prevent the calibration pulses from driving whatever
	   is connected to the board */
	sgpio_set_pin(dev, SGPIO_OUTPUT_EN(0), 0);
	sgpio_set_pin(dev, SGPIO_OUTPUT_EN(1), 0);
	sgpio_set_pin(dev, SGPIO_OUTPUT_EN(2), 0);
	sgpio_set_pin(dev, SGPIO_OUTPUT_EN(3), 0);

	/* Select internal trigger */
	sgpio_set_pin(dev, SGPIO_TRIG_SEL, 0);


	for(i=1;i<=4;i++) /* disable all other channels */
		if(channel != i)
			fd_writel(0, i * 0x100 + FD_REG_DCR);

	fd_readl(FD_REG_DMTR_IN);
	fd_readl(FD_REG_DMTR_OUT);

	fdelay_configure_trigger(dev, 1, 0);

	fd_writel(FD_CALR_PSEL_W(0) | FD_CALR_CAL_DMTD, FD_REG_CALR);
	
	init_dmtd(&ch_in, DMTD_OUTPUT_PERIOD);
	init_dmtd(&ch_out, DMTD_OUTPUT_PERIOD);
	
	n_in = n_out = 0;

	while(n_in < DMTD_N_AVGS || n_out < DMTD_N_AVGS) /* Get DMTD_N_AVGS samples to reduce error */
	{
		if(read_dmtd(dev, &ch_in, 0))
		 	if(n_in < DMTD_N_AVGS) samples_in[n_in++] = ch_in.phase;
		if(read_dmtd(dev, &ch_out, 1))
		 	if(n_out < DMTD_N_AVGS) samples_out[n_out++] = ch_out.phase;
	}

	for(i=0;i<DMTD_N_AVGS;i++)
	{
		delta[i] = samples_out[i] - samples_in[i];
		if(delta[i] < 0) delta[i] += DMTD_OUTPUT_PERIOD;
		// printf("in %lld out %lld delta %lld\n", samples_in[i], samples_out[i], delta[i]);
    }

	double avg = 0, s= 0;
	for(i=0;i<DMTD_N_AVGS;i++)
		avg+=(double) (delta[i]);
	avg/=(double)DMTD_N_AVGS;

	double scalefact = (double) (DMTD_PULSE_PERIOD * 16000 / 2) / (double)DMTD_OUTPUT_PERIOD;
	*mean = avg * scalefact;

	for(i=0;i<DMTD_N_AVGS;i++)
		s+=((double)delta[i]-avg) * ((double)delta[i]-avg);

	*std = sqrt(s / (double)(DMTD_N_AVGS-1)) * scalefact;

}


int fdelay_dmtd_calibration(fdelay_device_t *dev, double *offsets)
{   
	char resp[1024];
	char c;
	int i;
	fd_decl_private(dev)
    int64_t base = 0, prev_tag = -1;
    
	if(spec_load_lm32(dev->priv_io, "wrc.bin", 0xc0000))
	{
	 	dbg("Failed to load LM32 firmware\n");
	 	return -1;
	}
	
//	sleep(2);

	/* Configure the WR core to produce a proper calibration clock: */

	/* Disable PTP and enter free-running master mode */
	wrc_shell_exec(dev, "ptp stop", resp);
	wrc_shell_exec(dev, "mode master", resp);

	/* And lock the DMTD oscillator to the FMC clock instead of the SPEC 125 MHz oscillator. Set the FMC VCO DAC to 0
	   to have some headroom */
	wrc_shell_exec(dev, "pll sdac 1 0", resp);
	wrc_shell_exec(dev, "pll init 2 1 1", resp);

	/* Wait until the PLL locks... */
	while(1)
	{	
		wrc_shell_exec(dev, "pll cl 0", resp);
		if(!strcmp(resp, "1"))
			break;
		sleep(1);
	}
	
	double mean_out[4], std_out[4];

	usleep(500000);

	dbg("\n\nPerforming DDMTD delay calibration: \n");

	for(i=1;i<=4;i++)
	{
		calibrate_channel(dev, i, &mean_out[i-1], &std_out[i-1]);	
		dbg("Channel %d: delay %.0f ps, std %.0f ps.\n", i, mean_out[i-1], std_out[i-1]);
	}

	return 0;
}

