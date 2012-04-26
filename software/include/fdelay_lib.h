#ifndef __FD_LIB_H
#define __FD_LIB_H

#include <stdint.h>

/* Number of fractional bits in the timestamps/time definitions. Must be consistent with the HDL bitstream.  */
#define FDELAY_FRAC_BITS 12


/* fdelay_get_timing_status() return values: */

#define FDELAY_FREE_RUNNING	  0x10		/* attached WR core is offline */
#define FDELAY_WR_OFFLINE	  0x8		/* attached WR core is offline */
#define FDELAY_WR_READY 	  0x1		/* attached WR core is synchronized, we can sync the fine delay core anytime */
#define FDELAY_WR_SYNCING 	  0x2		/* local oscillator is being synchronized with WR clock */
#define FDELAY_WR_SYNCED   	  0x4		/* we are synced. */

/* fdelay_configure_sync() flags */

#define FDELAY_SYNC_LOCAL 	 0x1  	 	/* use local oscillator */
#define FDELAY_SYNC_WR	 	 0x2		/* use White Rabbit */

/* Hardware "handle" structure */
typedef struct fdelay_device
{
  /* Base address of the FD core */
  uint32_t base_addr; 

  /* Bus-specific readl/writel functions - so the same library can be used both with
     RawRabbit, VME and Etherbone backends */
  void (*writel)(void *priv, uint32_t data, uint32_t addr);
  uint32_t (*readl)(void *priv, uint32_t addr);
  
  void *priv_fd; /* pointer to Fine Delay library private data */
  void *priv_io; /* pointer to the I/O routines private data */
} fdelay_device_t;

typedef struct 
{
	int64_t utc;
	int32_t coarse;
	int32_t frac;
	uint16_t seq_id;
	int channel;
} fdelay_time_t;

/* 
--------------------
PUBLIC API 
--------------------
*/


fdelay_device_t *fdelay_create_rawrabbit(int fd, uint32_t base_addr);
fdelay_device_t *fdelay_create_minibone(char *iface, char *mac_addr, uint32_t base_addr);

fdelay_time_t fdelay_from_picos(const uint64_t ps);
int64_t fdelay_to_picos(const fdelay_time_t t);

int fdelay_init(fdelay_device_t *dev);
int fdelay_release(fdelay_device_t *dev);
int fdelay_read(fdelay_device_t *dev, fdelay_time_t *timestamps, int how_many);
int fdelay_configure_trigger(fdelay_device_t *dev, int enable, int termination);
int fdelay_configure_output(fdelay_device_t *dev, int channel, int enable, int64_t delay_ps, int64_t width_ps, int64_t delta_ps, int rep_count);

int fdelay_configure_sync(fdelay_device_t *dev, int mode);
int fdelay_update_sync_status(fdelay_device_t *dev);
int fdelay_set_time(fdelay_device_t *dev, const fdelay_time_t t);
int fdelay_configure_pulse_gen(fdelay_device_t *dev, int channel, int enable, fdelay_time_t t_start, int64_t width_ps, int64_t delta_ps, int rep_count);
int fdelay_channel_triggered(fdelay_device_t *dev, int channel);
int fdelay_get_time(fdelay_device_t *dev, fdelay_time_t *t);


#endif
