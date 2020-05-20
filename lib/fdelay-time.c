/*
 * Time-related functions
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
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <linux/zio.h>
#include <linux/zio-user.h>
#define FDELAY_INTERNAL
#include "fdelay-lib.h"

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

static char *names[] = {
	"utc-h",
	"utc-l",
	"coarse"
};

/**
 * Set board time
 * @param[in] userb device token
 * @param[in] t user time
 * @return 0 on success, otherwise -1 and errno is appropriately set.
 *
 * It only uses the fields *utc* and *coarse*.
 */
int fdelay_set_time(struct fdelay_board *userb, struct fdelay_time *t)
{
	__define_board(b, userb);
	uint32_t attrs[ARRAY_SIZE(names)];
	int i;

	attrs[0] = t->utc >> 32;
	attrs[1] = t->utc;
	attrs[2] = t->coarse;

	for (i = ARRAY_SIZE(names) - 1; i >= 0; i--)
		if (fdelay_sysfs_set(b, names[i], attrs + i) < 0)
			return -1;
	return 0;
}

/**
 * Get board time
 * @param[in] userb device token
 * @param[out] t board time
 * @return 0 on success, otherwise -1 and errno is appropriately set.
 *
 * It only uses the fields *utc* and *coarse*.
 */
int fdelay_get_time(struct fdelay_board *userb, struct fdelay_time *t)
{
	__define_board(b, userb);
	uint32_t attrs[ARRAY_SIZE(names)];
	int i;


	for (i = 0; i < ARRAY_SIZE(names); i++)
		if (fdelay_sysfs_get(b, names[i], attrs + i) < 0)
			return -1;
	t->utc = (long long)attrs[0] << 32;
	t->utc += attrs[1];
	t->coarse = attrs[2];
	return 0;
}

/**
 * Set board time to host time
 * @param[in] userb device token
 * @return 0 on success, otherwise -1 and errno is appropriately set.
 *
 * The precision should be in the order of 1 microsecond, but will drift over
 * time. This function is only provided to coarsely correlate the board time
 * with the system time. Relying on system time for synchronizing multiple
 * *fine-delays* is strongly discouraged.
 */
int fdelay_set_host_time(struct fdelay_board *userb)
{
	__define_board(b, userb);
	return __fdelay_command(b, FD_CMD_HOST_TIME);
}
