/*
 * TDC-related functions
 *
 * Copyright (C) 2012 CERN (www.cern.ch)
 * Author: Alessandro Rubini <rubini@gnudd.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2 as published by the Free Software Foundation or, at your
 * option, any later version.
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/select.h>

#include <linux/zio.h>
#include <linux/zio-user.h>
#define FDELAY_INTERNAL
#include "fdelay-lib.h"

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

static int config_mask =
	FD_TDCF_DISABLE_INPUT |
	FD_TDCF_DISABLE_TSTAMP |
	FD_TDCF_TERM_50;

/**
 * Configure TDC options
 * @param[in] userb device token
 * @param[in] flags is a bit-mask of FD_TDCF_* flags
 * @return 0 on success, otherwise -1 and errno is appropriately set.
 */
int fdelay_set_config_tdc(struct fdelay_board *userb, int flags)
{
	__define_board(b, userb);
	uint32_t val;

	if (flags & ~config_mask) {
		errno = EINVAL;
		return -1;
	}
	val = flags;
	return fdelay_sysfs_set(b, "fd-input/flags", &val);
}

/**
 * Configure TDC options
 * @param[in] userb device token
 * @return on success, a bit-mask of FD_TDCF_* flags; otherwise -1 and errno
 *         is appropriately set.
 */
int fdelay_get_config_tdc(struct fdelay_board *userb)
{
	__define_board(b, userb);
	uint32_t val;
	int ret;

	ret = fdelay_sysfs_get(b, "fd-input/flags", &val);
	if (ret) return ret;
	return val;
}

static int __fdelay_open_tdc(struct __fdelay_board *b)
{
	char fname[128];
	if (b->fdc[0] <= 0) {
		sprintf(fname, "%s-0-0-ctrl", b->devbase);
		b->fdc[0] = open(fname, O_RDONLY | O_NONBLOCK);
	}
	return b->fdc[0];
}

/**
 * Get TDC file descriptor
 * @param[in] userb device token
 * @return on success, a valid file descriptor; otherwise -1 and errno
 *         is appropriately set.
 *
 * This returns the file descriptor associated to the TDC device,
 * so you can *select* or *poll* before calling *fdelay_read*.
 */
int fdelay_fileno_tdc(struct fdelay_board *userb)
{
	__define_board(b, userb);
	return __fdelay_open_tdc(b);
}


/**
 * Read TDC timestamps
 * @param[in] userb device token
 * @param[out] t buffer for timestamps
 * @param[in] n maximum number that t can store
 * @param[in] flags for options: O_NONBLOCK for non blocking read
 * @return the number of valid timestamps in the buffer, otherwise -1
 *          and errno is appropriately set. EAGAIN if the driver buffer is
 *         empty
 */
int fdelay_read(struct fdelay_board *userb, struct fdelay_time *t, int n,
		       int flags)
{
	__define_board(b, userb);
	struct zio_control ctrl;
	uint32_t *attrs;
	int i, j, fd;
	fd_set set;

	fd = __fdelay_open_tdc(b);
	if (fd < 0)
		return fd; /* errno already set */

	for (i = 0; i < n;) {
		j = read(fd, &ctrl, sizeof(ctrl));
		if (j < 0 && errno != EAGAIN)
			return -1;
		if (j == sizeof(ctrl)) {
			/* one sample: pick it */
			attrs = ctrl.attr_channel.ext_val;
			t->utc = (uint64_t)attrs[FD_ATTR_TDC_UTC_H] << 32
				| attrs[FD_ATTR_TDC_UTC_L];
			t->coarse = attrs[FD_ATTR_TDC_COARSE];
			t->frac = attrs[FD_ATTR_TDC_FRAC];
			t->seq_id = attrs[FD_ATTR_TDC_SEQ];
			t->channel = attrs[FD_ATTR_TDC_CHAN];
			t++;
			i++;
			continue;
		}
		if (j > 0) {
			errno = EIO;
			return -1;
		}
		/* so, it's EAGAIN: if we already got something, we are done */
		if (i)
			return i;
		/* EAGAIN at first sample */
		if (j < 0 && flags == O_NONBLOCK)
			return -1;

		/* So, first sample and blocking read. Wait.. */
		FD_ZERO(&set);
		FD_SET(fd, &set);
		if (select(fd+1, &set, NULL, NULL, NULL) < 0)
			return -1;
		continue;
	}
	return i;
}

/**
 * Read TDC timestamps
 * @param[in] userb device token
 * @param[out] t buffer for timestamps
 * @param[in] n maximum number that t can store
 * @return the number of valid timestamps in the buffer, otherwise -1
 *         and errno is appropriately set.
 *
 * The function behaves like *fread*: it tries to read all samples,
 * even if it implies sleeping several times.  Use it only if you are
 * aware that all the expected pulses will reach you.
 */
int fdelay_fread(struct fdelay_board *userb, struct fdelay_time *t, int n)
{
	int i, loop;

	for (i = 0; i < n; ) {
		loop = fdelay_read(userb, t + i, n - i, 0);
		if (loop < 0)
			return -1;
		i += loop;
	}
	return i;
}
