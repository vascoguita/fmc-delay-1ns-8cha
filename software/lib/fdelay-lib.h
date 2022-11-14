// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: LGPL-2.1-or-later

#ifndef __FDELAY_H__
#define __FDELAY_H__

/**
 * Most of the client are written in C++
 */
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdint.h>
#include "fine-delay.h"

#define __FDELAY_ERR_MIN 4096
enum fmctdc_error_numbers {
	FDELAY_ERR_VERSION_MISMATCH = __FDELAY_ERR_MIN,
	__FDELAY_ERR_MAX,
};

/**
 * Convert the internal channel number to the one showed on the front-panel
 */
#define FDELAY_OUTPUT_HW_TO_USER(out) ((out) + 1)

/**
 * Convert the channel number showed on the front-panel to the
 * internal enumeration
 */
#define FDELAY_OUTPUT_USER_TO_HW(out) ((out) - 1)

  /**
   * Opaque data type used as device token
   */
  struct fdelay_board;

  /**
   * Time descriptor
   */
  struct fdelay_time {
    uint64_t utc; /**< seconds */
    uint32_t coarse; /**< 8ns step (125MHz clock)*/
    uint32_t frac; /**< coarse fractional part in 1.953125ps steps */
    uint32_t seq_id; /**< time-stamp sequence number, used only by the TDC */
    uint32_t channel; /**< channel number, used only by the TDC
			 as debug information */
  };

  /**
   * The structure used for pulse generation
   */
  struct fdelay_pulse {
    int mode; /**< pulse mode must be one of the followings:
		 FD_OUT_MODE_DISABLED, FD_OUT_MODE_DELAY,
		 FD_OUT_MODE_PULSE */
    int rep; /**< number of pulse repetitions,
		maximum 65535 or 0 for infinite */
    struct fdelay_time start; /**< rasising edge time */
    struct fdelay_time end; /**< falling edge time */
    struct fdelay_time loop; /**< period time */
  };

  /**
   * The alternative structure used for pulse generation
   * (internally converted to the previous one)
   */
  struct fdelay_pulse_ps {
    int mode; /**< pulse mode must be one of the followings:
		 FD_OUT_MODE_DISABLED, FD_OUT_MODE_DELAY,
		 FD_OUT_MODE_PULSE */
    int rep; /**< number of pulse repetitions,
		maximum 65535 or 0 for infinite */
    struct fdelay_time start; /**< rasising edge time */
    uint64_t length; /**< pulse width in pico-seconds */
    uint64_t period; /**< pulse period in pico-seconds */
  };

  extern int fdelay_init(void);
  extern void fdelay_exit(void);
  extern const char *fdelay_strerror(int err);

  extern struct fdelay_board *fdelay_open(int dev_id);
  extern struct fdelay_board *fdelay_open_by_lun(int lun);
  extern int fdelay_close(struct fdelay_board *);

  extern int fdelay_set_time(struct fdelay_board *b, struct fdelay_time *t);
  extern int fdelay_get_time(struct fdelay_board *b, struct fdelay_time *t);
  extern int fdelay_set_host_time(struct fdelay_board *b);

  extern int fdelay_set_config_tdc(struct fdelay_board *b, int flags);
  extern int fdelay_get_config_tdc(struct fdelay_board *b);

  extern int fdelay_fread(struct fdelay_board *b, struct fdelay_time *t, int n);
  extern int fdelay_fileno_tdc(struct fdelay_board *b);
  extern int fdelay_read(struct fdelay_board *b, struct fdelay_time *t, int n,
			 int flags);

  extern void fdelay_pico_to_time(uint64_t *pico, struct fdelay_time *time);
  extern void fdelay_time_to_pico(struct fdelay_time *time, uint64_t *pico);

  extern int fdelay_config_pulse(struct fdelay_board *b,
				 int channel, struct fdelay_pulse *pulse);
  extern int fdelay_config_pulse_ps(struct fdelay_board *b,
				    int channel, struct fdelay_pulse_ps *ps);
  extern int fdelay_has_triggered(struct fdelay_board *b, int channel);

  extern int fdelay_wr_mode(struct fdelay_board *b, int on);
  extern int fdelay_check_wr_mode(struct fdelay_board *b);

  extern float fdelay_read_temperature(struct fdelay_board *b);

  extern int fdelay_get_config_pulse(struct fdelay_board *userb,
				     int channel, struct fdelay_pulse *pulse);
  extern int fdelay_get_config_pulse_ps(struct fdelay_board *userb,
					int channel, struct fdelay_pulse_ps *ps);

  /**
   * libfmctdc version string
   */
  extern const char * const libfdelay_version_s;
  /**
   * zio version string used during compilation of libfmctdc
   */
  extern const char * const libfdelay_zio_version_s;

#ifdef FDELAY_INTERNAL /* Libray users should ignore what follows */
#include <unistd.h>
#include <fcntl.h>
#include <inttypes.h>
#include <sys/types.h>
#include <sys/stat.h>

/* Internal structure */
struct __fdelay_board {
	int dev_id;
	char *devbase;
	char *sysbase;
	int fdc[5]; /* The 5 control channels */
};

static inline int fdelay_is_verbose(void)
{
	return getenv("FDELAY_LIB_VERBOSE") != 0;
}

#define __define_board(b, ub)	struct __fdelay_board *b = (void *)(ub)

/* These two from ../tools/fdelay-raw.h, used internally */
static inline int __fdelay_sysfs_get(char *path, uint32_t *resp)
{
	FILE *f = fopen(path, "r");

	if (!f)
		return -1;
	errno = 0;
	if (fscanf(f, "%"SCNu32, resp) != 1) {
		fclose(f);
		if (!errno)
			errno = EINVAL;
		return -1;
	}
	fclose(f);
	return 0;
}

static inline int __fdelay_sysfs_set(char *path, uint32_t *value)
{
	char s[16];
	int fd, ret, len;

	len = sprintf(s, "%"PRIu32"\n", *value);
	fd = open(path, O_WRONLY);
	if (fd < 0)
		return -1;
	ret = write(fd, s, len);
	close(fd);
	if (ret < 0)
		return -1;
	if (ret == len)
		return 0;
	errno = EINVAL;
	return -1;
}

/* And these two for the board structure */
static inline int fdelay_sysfs_get(struct __fdelay_board *b, char *name,
			       uint32_t *resp)
{
	char pathname[128];

	snprintf(pathname, sizeof(pathname), "%s/%s", b->sysbase, name);
	return __fdelay_sysfs_get(pathname, resp);
}

static inline int fdelay_sysfs_set(struct __fdelay_board *b, char *name,
			       uint32_t *value)
{
	char pathname[128];

	snprintf(pathname, sizeof(pathname), "%s/%s", b->sysbase, name);
	return __fdelay_sysfs_set(pathname, value);
}

static inline int __fdelay_command(struct __fdelay_board *b, uint32_t cmd)
{
	return fdelay_sysfs_set(b, "command", &cmd);
}
#endif /* FDELAY_INTERNAL */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __FDELAY_H__ */
