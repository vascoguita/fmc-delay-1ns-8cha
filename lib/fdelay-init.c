/*
 * Initializing and cleaning up the fdelay library
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
#include <glob.h>
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

const char * const libfdelay_version_s = "libfdelay version: " GIT_VERSION;
const char * const libfdelay_zio_version_s = "libfdelay is using zio version: " ZIO_GIT_VERSION;

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

/* Init the library: return the number of boards found */
int fdelay_init(void)
{
	return 0;
}

/* Free and check */
void fdelay_exit(void)
{
	return ;
}

/**
 * It opens one specific device. -1 arguments mean "not installed"
 * @param[in] dev_id FMC device id. -1 to ignore it and use only the offset
 * @return an instance token, otherwise NULL and errno is appripriately set.
 *         ENODEV if the device was not found. EINVAL there is a mismatch with
 *         the arguments
 */
#define __FMCTDC_OPEN_PATH_MAX 128
struct fdelay_board *fdelay_open(int dev_id)
{
	struct __fdelay_board *b = NULL;
	char path[__FMCTDC_OPEN_PATH_MAX];
	struct stat sb;
	uint32_t v;
	int ret;

	if (dev_id < 0) {
		errno = EINVAL;
		return NULL;
	}

	b = malloc(sizeof(*b));
	if (!b)
		return NULL;
	memset(b, 0, sizeof(*b));

	/* get sysfs */
	snprintf(path, sizeof(path),
		 "/sys/bus/zio/devices/fd-%04x", dev_id);
	ret = stat(path, &sb);
	if (ret < 0)
		goto err_stat_s;
	if (!S_ISDIR(sb.st_mode))
		goto err_stat_s;
	b->sysbase = strdup(path);

	/* get dev */
	snprintf(path, sizeof(path),
		 "/dev/zio/fd-%04x-0-0-ctrl", dev_id);
	ret = stat(path, &sb);
	if (ret < 0)
		goto err_stat_d;
	if (!S_ISCHR(sb.st_mode))
		goto err_stat_d;
	b->devbase = strndup(path, strlen(path) - strlen("-0-0-ctrl"));

	ret = fdelay_sysfs_get(b, "version", &v);
	if (ret)
		goto err_version;

	if (v != FDELAY_VERSION_MAJ) {
		errno = FDELAY_ERR_VERSION_MISMATCH;
		goto err_version;
	}

	return (void *)b;

err_version:
	free(b->devbase);
err_stat_d:
	free(b->sysbase);
err_stat_s:
	free(b);
	return NULL;
}

/* Open one specific device by logical unit number (CERN/CO-like) */
struct fdelay_board *fdelay_open_by_lun(int lun)
{
	ssize_t ret;
	char dev_id_str[4];
	char path_pattern[] = "/dev/fine-delay.%d";
	char path[sizeof(path_pattern) + 1];
	int dev_id;

	if (fdelay_is_verbose())
		fprintf(stderr, "called: %s(lun %i);\n", __func__, lun);
	ret = snprintf(path, sizeof(path), path_pattern, lun);
	if (ret < 0 || ret >= sizeof(path)) {
		errno = EINVAL;
		return NULL;
	}
	ret = readlink(path, dev_id_str, sizeof(dev_id_str));
	if (sscanf(dev_id_str, "%4x", &dev_id) != 1) {
		errno = ENODEV;
		return NULL;
	}
	return fdelay_open(dev_id);
}

int fdelay_close(struct fdelay_board *userb)
{
	struct __fdelay_board *b = (struct __fdelay_board *)userb;
	int j;

	for (j = 0; j < ARRAY_SIZE(b->fdc); j++) {
		if (b->fdc[j] >= 0)
			close(b->fdc[j]);
	}

	free(b->sysbase);
	free(b->devbase);
	free(b);
	return 0;

}

int fdelay_wr_mode(struct fdelay_board *userb, int on)
{
	__define_board(b, userb);
	if (on)
		return __fdelay_command(b, FD_CMD_WR_ENABLE);
	else
		return __fdelay_command(b, FD_CMD_WR_DISABLE);
}

extern int fdelay_check_wr_mode(struct fdelay_board *userb)
{
	__define_board(b, userb);
	if (__fdelay_command(b, FD_CMD_WR_QUERY) == 0)
		return 0;
	return errno;
}

float fdelay_read_temperature(struct fdelay_board *userb)
{
	uint32_t t;
	__define_board(b, userb);

	fdelay_sysfs_get(b, "temperature", &t);
	return (float)t/16.0;
}

static const char *fdelay_error_string[] = {
	[FDELAY_ERR_VERSION_MISMATCH - __FDELAY_ERR_MIN] =
		"Incompatible version driver-library",
};

/**
 * It returns the error message associated to the given error code
 * @param[in] err error code
 */
const char *fdelay_strerror(int err)
{
	if (err < __FDELAY_ERR_MIN || err > __FDELAY_ERR_MAX)
		return strerror(err);
	return fdelay_error_string[err - __FDELAY_ERR_MIN];
}
