// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: LGPL-2.1-or-later

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

/**
 * Initialize the fdelay library. It must be called before doing
 * anything else.
 * @return 0 on success, otherwise -1 and errno is appropriately set
 */
int fdelay_init(void)
{
	return 0;
}

/**
 * Release the resources allocated by fdelay_init(). It must be called when
 * you stop to use this library. Then, you cannot use functions from this
 * library anymore.
 */
void fdelay_exit(void)
{
	return ;
}

/**
 * It opens one specific device.
 * @param[in] dev_id Fine Delay device id.
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
	b->devbase = strndup(path, strnlen(path, sizeof(path)) - strlen("-0-0-ctrl"));

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

/**
 * It opens one specific device using the logical unit number (CERN/CO-like)
 * @param[in] lun Fine Delay LUN.
 * @return an instance token, otherwise NULL and errno is appripriately set.
 *         ENODEV if the device was not found. EINVAL there is a mismatch with
 *         the arguments
 *
 * The function uses a symbolic link in /dev, created by the local
 * installation procedure.
 */
struct fdelay_board *fdelay_open_by_lun(int lun)
{
	ssize_t ret;
	char dev_id_str[4];
	char path_pattern[] = "/dev/fd.%d";
	char path[sizeof(path_pattern) + 1];
	uint32_t dev_id;

	if (fdelay_is_verbose())
		fprintf(stderr, "called: %s(lun %i);\n", __func__, lun);
	ret = snprintf(path, sizeof(path), path_pattern, lun);
	if (ret < 0 || ret >= sizeof(path)) {
		errno = EINVAL;
		return NULL;
	}
	ret = readlink(path, dev_id_str, sizeof(dev_id_str));
	if (ret < 0) {
		errno = ENODEV;
		return NULL;
	}
	if (sscanf(dev_id_str, "%4"SCNx32, &dev_id) != 1) {
		errno = ENODEV;
		return NULL;
	}
	return fdelay_open(dev_id);
}

/**
 * Close an FMC Fine Delay device opened with one of the following functions:
 * fdelay_open(), fdelay_open_by_lun()
 * @param[in] userb device token
 * @return 0 on success, otherwise -1 and errno is appropriately set
 */
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

/**
 * Enable or disable White-Rabbit time
 * @param[in] userb device token
 * @param[in] on 1 to enable, 0 to disable
 * @return 0 on success, otherwise an errno code.
 *         ENOTSUP when White-Rabbit is not supported
 */
int fdelay_wr_mode(struct fdelay_board *userb, int on)
{
	__define_board(b, userb);
	if (on)
		return __fdelay_command(b, FD_CMD_WR_ENABLE);
	else
		return __fdelay_command(b, FD_CMD_WR_DISABLE);
}

/**
 * Check White-Rabbit status
 * @param[in] userb device token
 * @return 0 if White-Rabbit is enabled, ENOTSUP when White-Rabbit is
 *         not supported, ENODEV if White-Rabbit is disabled, ENOLINK if the
 *         White-Rabbit link is down
 */
extern int fdelay_check_wr_mode(struct fdelay_board *userb)
{
	__define_board(b, userb);
	if (__fdelay_command(b, FD_CMD_WR_QUERY) == 0)
		return 0;
	return errno;
}

/**
 * Read the FMC Fine Delay temperature
 * @param[in] userb device token
 * @return temperature
 */
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
