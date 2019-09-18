// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <inttypes.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <endian.h>

#include <fine-delay.h>

static const char program_name[] = "fau-calibration";
static char options[] = "hf:o:D:b";
static const char help_msg[] =
	"Usage: fmc_fdelay_-calibration [options]\n"
	"\n"
	"It reads calibration data from a file that contains it in binary\n"
	"form and it shows it on STDOUT in binary form or in human readable\n"
	"one (default).\n"
	"This could be used to change the FDelay calibration data at runtime\n"
	"by redirectiong the binary output of this program to the proper \n"
	"sysfs binary attribute\n"
	"Rembember that we expect all values to be big endian\n"
	"\n"
	"General options:\n"
	"-h                 Print this message\n"
	"-b                 Show Calibration in binary form \n"
	"\n"
	"Read options:\n"
	"-f                 Source file where to read calibration data from\n"
	"-o                 Offset in bytes within the file (default 0)\n"
	"Write options:\n"
	"-D                 FMC FDelay Target Device ID\n"
	"\n";

/**
 * Read calibration data from file
 * @path: file path
 * @calib: calibration data
 * @offset: offset in file
 *
 * Return: number of bytes read
 */
static int fmc_fdelay_calibration_read(char *path,
				       struct fd_calibration *calib,
				       off_t offset)
{
	int fd;
	int ret = 0;

	fd = open(path, O_RDONLY);
	if (fd < 0)
		return -1;
	ret = lseek(fd, offset, SEEK_SET);
	if (ret >= 0)
		ret = read(fd, calib, sizeof(*calib));
	close(fd);

	return ret;
}

/**
 * Print calibration data on stdout in humand readable format
 * @calib: calibration data
 */
static void fmc_fdelay_calibration_dump_human(struct fd_calibration *calib)
{
	int i;

	/* Fix Endianess */
	calib->magic = be32toh(calib->magic);
	calib->hash = be32toh(calib->hash);
	calib->size = be16toh(calib->size);
	calib->version = be16toh(calib->version);
	calib->date = be32toh(calib->date);
	for (i = 0; i < 3; ++i)
		calib->frr_poly[i] = be64toh(calib->frr_poly[i]);
	for (i = 0; i < 4; ++i)
		calib->zero_offset[i] = be32toh(calib->zero_offset[i]);
	calib->tdc_zero_offset = be32toh(calib->tdc_zero_offset);
	calib->vcxo_default_tune = be32toh(calib->vcxo_default_tune);

	fprintf(stdout, "Signature      : 0x%08"PRIx32"\n", calib->magic);
	fprintf(stdout, "Hash           : 0x%08"PRIx32"\n", calib->hash);
	fprintf(stdout, "Size           : %08"PRId16"\n", calib->size);
	fprintf(stdout, "Version        : %08"PRId16"\n", calib->version);
	fprintf(stdout, "Date           : 0x%08"PRIx32"\n", calib->date);
	for (i =0; i < 3; ++i)
		fprintf(stdout, "FRR-poly[%d]       : 0x%016"PRIx64"\n", i,
			calib->frr_poly[i]);
	for (i =0; i < 4; ++i)
		fprintf(stdout, "zero-offset[%d]    : 0x%016"PRIx32"\n", i,
			calib->zero_offset[i]);
	fprintf(stdout, "TDC-zero-offset : 0x%08"PRIx32"\n", calib->tdc_zero_offset);
	fprintf(stdout, "VCXO tune       : 0x%08"PRIx32"\n",
		calib->vcxo_default_tune);
	fputc('\n', stdout);
}

/**
 * Print binary calibration data on stdout
 * @calib: calibration data
 */
static void fmc_fdelay_calibration_dump_machine(struct fd_calibration *calib)
{
	write(fileno(stdout), calib, sizeof(*calib));
}

/**
 * Write calibration data to device
 * @devid: Device ID
 * @calib: calibration data
 *
 * Return: number of bytes wrote
 */
static int fmc_fdelay_calibration_write(unsigned int devid, struct fd_calibration *calib)
{
	char path[128];
	int fd;
	int ret;

	sprintf(path,
		"/sys/bus/zio/devices/fd-%04x/calibration_data",
		devid);

	fd = open(path, O_WRONLY);
	if (fd < 0)
		return -1;
	ret = write(fd, calib, sizeof(*calib));
	close(fd);

	return ret;
}

int main(int argc, char *argv[])
{
	char c;
	int ret;
	char *path = NULL;
	unsigned int offset = 0;
	unsigned int devid = 0;
	int show_bin = 0, write = 0;
	struct fd_calibration calib;

	while ((c = getopt(argc, argv, options)) != -1) {
		switch (c) {
		default:
		case 'h':
			fprintf(stderr, help_msg);
			exit(EXIT_SUCCESS);
		case 'D':
			ret = sscanf(optarg, "0x%x", &devid);
			if (ret != 1) {
				fprintf(stderr,
					"Invalid devid %s\n",
					optarg);
				exit(EXIT_FAILURE);
			}
			write = 1;
			break;
		case 'f':
			path = optarg;
			break;
		case 'o':
			ret = sscanf(optarg, "0x%x", &offset);
			if (ret != 1) {
				ret = sscanf(optarg, "%u", &offset);
				if (ret != 1) {
					fprintf(stderr,
						"Invalid offset %s\n",
						optarg);
					exit(EXIT_FAILURE);
				}
			}
			break;
		case 'b':
			show_bin = 1;
			break;
		}
	}

	if (!path) {
		fputs("Calibration file is mandatory\n", stderr);
		exit(EXIT_FAILURE);
	}

	/* Read EEPROM file */
	ret = fmc_fdelay_calibration_read(path, &calib, offset);
	if (ret < 0) {
		fprintf(stderr, "Can't read calibration data from '%s'. %s\n",
			path, strerror(errno));
		exit(EXIT_FAILURE);
	}
	if (ret != sizeof(calib)) {
		fprintf(stderr,
			"Can't read all calibration data from '%s'. %s\n",
			path, strerror(errno));
		exit(EXIT_FAILURE);
	}

	/* Show calibration data*/
	if (show_bin)
		fmc_fdelay_calibration_dump_machine(&calib);
	else if(!write)
		fmc_fdelay_calibration_dump_human(&calib);

	/* Write calibration data */
	if (write) {
		ret = fmc_fdelay_calibration_write(devid, &calib);
		if (ret < 0) {
			fprintf(stderr,
				"Can't write calibration data to '0x%x'. %s\n",
				devid, strerror(errno));
			exit(EXIT_FAILURE);
		}
		if (ret != sizeof(calib)) {
			fprintf(stderr,
				"Can't write all calibration data to '0x%x'. %s\n",
				devid, strerror(errno));
			exit(EXIT_FAILURE);
		}
	}
	exit(EXIT_SUCCESS);
}
