#ifndef __FD_LIB_H
#define __FD_LIB_H

#include <stdint.h>

/* Number of fractional bits in the timestamps/time definitions. Must be consistent with the HDL bitstream.  */
#define FDELAY_FRAC_BITS 12


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
	uint32_t utc;
	uint32_t coarse;
	uint32_t frac;
	uint16_t seq_id;
} fdelay_time_t;

/* 
--------------------
PUBLIC API 
--------------------
*/

fdelay_time_t fdelay_from_picos(const uint64_t ps);
int64_t fdelay_to_picos(const fdelay_time_t t);

int fdelay_init(fdelay_device_t *dev);
int fdelay_release(fdelay_device_t *dev);
int fdelay_read(fdelay_device_t *dev, fdelay_time_t *timestamps, int how_many);
int fdelay_configure_trigger(fdelay_device_t *dev, int enable, int termination);
int fdelay_configure_output(fdelay_device_t *dev, int channel, int enable, int64_t delay_ps, int64_t width_ps);

#endif
