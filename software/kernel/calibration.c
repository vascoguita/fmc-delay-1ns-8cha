// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include <linux/time.h>
#include <linux/jhash.h>
#include <linux/stat.h>
#include <linux/slab.h>
#include <linux/zio.h>
#include "fine-delay.h"

static struct fd_calibration fd_calib_default = {
	.magic = FD_MAGIC_FPGA,
	.version = 3,
	.date = 0x20130427,
	.frr_poly = { -165202LL, -29825595LL, 3801939743082LL },
	.zero_offset = { -38186, -38155, -38147, -38362 },
	.tdc_zero_offset = 127500,
	.vcxo_default_tune = 41711,
};

static off_t fd_calib_find_offset(const void *data, size_t len)
{
	int i;

	for (i = 0; i < len; i += 4) {
		uint32_t sign = be32_to_cpup((const uint32_t *)(data + i));

		if (sign == FD_MAGIC_FPGA)
			return i;
	}

	return -ENODATA;
}

/**
 * @calib: calibration data
 *
 * We know for sure that our structure is only made of 16bit fields
 */
static void fd_calib_endianess_to_cpus(struct fd_calibration *calib)
{
	int i;

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
}

/**
 * @calib: calibration data
 *
 * We know for sure that our structure is only made of 16bit fields
 */
static void fd_calib_cpu_to_endianess(struct fd_calibration *calib)
{
	int i;

	calib->magic = cpu_to_be32(calib->magic);
	calib->size = cpu_to_be16(calib->size);
	calib->version = cpu_to_be16(calib->version);
	calib->date = cpu_to_be32(calib->date);
	for (i = 0; i < ARRAY_SIZE(calib->frr_poly); i++)
		calib->frr_poly[i] = cpu_to_be64(calib->frr_poly[i]);
	for (i = 0; i < ARRAY_SIZE(calib->zero_offset); i++)
		calib->zero_offset[i] = cpu_to_be32(calib->zero_offset[i]);
	calib->tdc_zero_offset = cpu_to_be32(calib->tdc_zero_offset);
	calib->vcxo_default_tune = cpu_to_be32(calib->vcxo_default_tune);

}

static int fd_verify_calib(struct device *msgdev, struct fd_calibration *calib)
{
	uint32_t horig = 0, hash = 0;

	horig = be32_to_cpu(calib->hash);
	calib->hash = 0;
	hash = jhash(calib, sizeof(*calib), 0);

	if (hash != horig) {
		dev_err(msgdev,
			"Calibration hash %08x is wrong (expected %08x)\n",
			hash, horig);
		return -EINVAL;
	}

	calib->hash = hash;

	return 0;
}

static void __fd_calib_write(struct fd_dev *fd, struct fd_calibration *calib)
{
	struct fd_calibration *calib_good = calib;
	int err;

	err = fd_verify_calib(&fd->pdev->dev, calib);
	if (err) {
		dev_info(&fd->pdev->dev, "Apply Calibration Identity\n");
		calib_good = &fd_calib_default;
	} else {
		fd_calib_endianess_to_cpus(calib);

		if (calib->version < 3) {
			dev_err(&fd->pdev->dev,
				"Calibration version %i < 3: refusing to work\n. Use identity",
				calib->version);
			calib_good = &fd_calib_default;
		}
	}

	memcpy(&fd->calib, calib_good, sizeof(fd->calib));


	if (fd->verbose) {
		int i;

		dev_info(&fd->pdev->dev,
			 "calibration: version %i, date %08x\n",
			 fd->calib.version, fd->calib.date);
		/* dump human-readable values */
		dev_info(&fd->pdev->dev, "calib: magic 0x%08x\n",
			 fd->calib.magic);
		for (i = 0; i < ARRAY_SIZE(fd->calib.frr_poly); i++)
			dev_info(&fd->pdev->dev, "calib: poly[%i] = %lli\n",
				 i, (long long)fd->calib.frr_poly[i]);
		for (i = 0; i < ARRAY_SIZE(fd->calib.zero_offset); i++)
			dev_info(&fd->pdev->dev, "calib: offset[%i] = %li\n",
				 i, (long)fd->calib.zero_offset[i]);
		dev_info(&fd->pdev->dev, "calib: tdc_offset %i\n",
			 fd->calib.tdc_zero_offset);
		dev_info(&fd->pdev->dev, "calib: vcxo %i\n",
			 fd->calib.vcxo_default_tune);
	}
}

static ssize_t fd_calib_write(struct file *file, struct kobject *kobj,
			      struct bin_attribute *attr,
			      char *buf, loff_t off, size_t count)
{
	struct device *dev = container_of(kobj, struct device, kobj);
	struct fd_dev *fd = to_zio_dev(dev)->priv_d;
	struct fd_calibration *calib = (struct fd_calibration *)buf;

	if (off != 0 || count != sizeof(*calib))
		return -EINVAL;

	__fd_calib_write(fd, calib);

	return count;
}

static ssize_t fd_calib_read(struct file *file, struct kobject *kobj,
			     struct bin_attribute *attr,
			     char *buf, loff_t off, size_t count)
{
	struct device *dev = container_of(kobj, struct device, kobj);
	struct fd_dev *fd = to_zio_dev(dev)->priv_d;
	struct fd_calibration *calib = (struct fd_calibration *) buf;


	if (off != 0 || count < sizeof(fd->calib))
		return -EINVAL;

	memcpy(calib, &fd->calib, sizeof(fd->calib));
	fd_calib_cpu_to_endianess(calib);

	return count;
}

struct bin_attribute dev_attr_calibration = {
	.attr = {
		.name = "calibration_data",
		.mode = 0644,
	},
	.size = sizeof(struct fd_calibration),
	.write = fd_calib_write,
	.read = fd_calib_read,
};

#define IPMI_FRU_SIZE 256
#define FD_EEPROM_SIZE (1024 * 8) /* 8KiB */

int fd_calib_init(struct fd_dev *fd)
{
	struct fd_calibration calib;
	const size_t data_len = FD_EEPROM_SIZE - IPMI_FRU_SIZE;
	void *data;
	off_t calib_offset;
	int ret;

	data = kmalloc(data_len, GFP_KERNEL);
	if (!data)
		goto err;
	ret = fmc_slot_eeprom_read(fd->slot, data, IPMI_FRU_SIZE, data_len);
	if (ret < 0) {
		kfree(data);
		goto err;
	}

	calib_offset = fd_calib_find_offset(data, data_len);
	kfree(data);
	if (calib_offset < 0)
		goto err;
	memcpy(&calib, data + calib_offset, sizeof(calib));
	__fd_calib_write(fd, &calib);

	return 0;

err:
	dev_warn(&fd->pdev->dev,
		 "Failed to get calibration from EEPROM: using identity calibration\n");
	memcpy(&fd->calib, &fd_calib_default, sizeof(fd->calib));

	return 0;
}

void fd_calib_exit(struct fd_dev *fd)
{

}
