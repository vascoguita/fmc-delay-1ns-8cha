/*
 * Code related to on-eeprom calibration: retrieving, defaulting, updating.
 *
 * Copyright (C) 2013 CERN (www.cern.ch)
 * Author: Alessandro Rubini <rubini@gnudd.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2 as published by the Free Software Foundation or, at your
 * option, any later version.
 */

#include <linux/time.h>
#include <linux/jhash.h>
#include <linux/stat.h>
#include "fine-delay.h"


static struct fd_calibration fd_calib_default = {
	.magic = 0xf19ede1a,
	.version = 3,
	.date = 0x20130427,
	.frr_poly = { -165202LL, -29825595LL, 3801939743082LL },
	.zero_offset = { -38186, -38155, -38147, -38362 },
	.tdc_zero_offset = 127500,
	.vcxo_default_tune = 41711,
};

/* This is the only thing called by outside */
int fd_handle_calibration(struct fd_dev *fd, struct fd_calibration *calib)
{
	struct device *d = &fd->pdev->dev;
	u32 horig = 0, hash = 0;
	int i;

	if (calib) {
		/* save old hash and compute it again before fixing endianess */
		horig = be32_to_cpu(calib->hash);
		calib->hash = 0;
		hash = jhash(calib, sizeof(*calib), 0);

		/* fix endianess from SDBFS */
		calib->magic = be32_to_cpu(calib->magic);
		calib->size = be16_to_cpu(calib->size);
		calib->version = be16_to_cpu(calib->version);
		calib->date = be32_to_cpu(calib->date);
		for (i = 0; i < ARRAY_SIZE(calib->frr_poly); i++)
			calib->frr_poly[i] = be64_to_cpu(calib->frr_poly[i]);
		for (i = 0; i < ARRAY_SIZE(calib->zero_offset); i++)
			calib->zero_offset[i] = be32_to_cpu(calib->zero_offset[i]);
		calib->tdc_zero_offset = be32_to_cpu(calib->tdc_zero_offset);
		calib->vcxo_default_tune = be32_to_cpu(calib->vcxo_default_tune);

	} else {
		dev_info(d, "calibration: overriding with default values\n");
		calib = &fd_calib_default;
	}

	if (fd->verbose) {
		dev_info(d, "calibration: version %i, date %08x\n",
			 calib->version, calib->date);
		/* dump human-readable values */
		dev_info(d, "calib: magic 0x%08x\n", calib->magic);
		for (i = 0; i < ARRAY_SIZE(calib->frr_poly); i++)
			dev_info(d, "calib: poly[%i] = %lli\n", i,
				 (long long)calib->frr_poly[i]);
		for (i = 0; i < ARRAY_SIZE(calib->zero_offset); i++)
			dev_info(d, "calib: offset[%i] = %li\n", i,
				 (long)calib->zero_offset[i]);
		dev_info(d, "calib: tdc_offset %i\n",
			 calib->tdc_zero_offset);
		dev_info(d, "calib: vcxo %i\n", calib->vcxo_default_tune);
	}

	if (hash != horig) {
		dev_err(d, "Calibration hash %08x is wrong (expected %08x)\n",
			hash, horig);
		return -EINVAL;
	}
	if (calib->version < 3) {
		dev_err(d, "Calibration version %i < 3: refusing to work\n",
			calib->version);
		return -EINVAL;
	}

	fd->calib = *calib;
	fd->calib.hash = hash;

	return 0;
}

static ssize_t fd_write_eeprom(struct file *file, struct kobject *kobj,
			       struct bin_attribute *attr,
			       char *buf, loff_t off, size_t count)
{
	struct device *dev = container_of(kobj, struct device, kobj);
	struct platform_device *pdev = to_platform_device(dev);
	struct fd_dev *fd = platform_get_drvdata(pdev);
	struct fd_calibration *calib = (struct fd_calibration *)(buf + 0x240);
	int ret;

	if (off >= (4 * 1024)) {
		/*
		 * We do care only about the data in the first 4K of
		 * the eeprom. Just, acknowledge any other page
		 */
		return count;
	}

	if (count < 0x240 + sizeof(struct fd_calibration)) {
		dev_err(dev, "Invalid eeprom size\n");
		return -EINVAL;
	}
	ret = fd_handle_calibration(fd, calib);
	return ret ? ret : count;
}
struct bin_attribute dev_attr_eeprom = {
	.attr = {
		.name = "eeprom",
		.mode = S_IWUSR,
	},
	.size = (8 * 1024), /* 8 KiB */
	.write = fd_write_eeprom,
};
