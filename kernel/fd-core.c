/*
 * core fine-delay driver (i.e., init and exit of the subsystems)
 *
 * Copyright (C) 2012 CERN (www.cern.ch)
 * Author: Alessandro Rubini <rubini@gnudd.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2 as published by the Free Software Foundation or, at your
 * option, any later version.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/interrupt.h>
#include <linux/spinlock.h>
#include <linux/bitops.h>
#include <linux/delay.h>
#include <linux/slab.h>
#include <linux/init.h>
#include <linux/list.h>
#include <linux/io.h>
#include <linux/platform_device.h>
#include <linux/ipmi-fru.h>
#include <linux/fmc.h>

#include "fine-delay.h"
#include "hw/fd_main_regs.h"

/* Module parameters */
static int fd_verbose = 0;
module_param_named(verbose, fd_verbose, int, 0444);

#define FA_EEPROM_TYPE "at24c64"

/* FIXME: add parameters "file=" and "wrc=" like wr-nic-core does */

/**
 * fd_do_reset
 * The reset function (by Tomasz)
 *
 * This function can reset the entire mezzanine (FMC) or just
 * the fine-delay core (CORE).
 * In the reset register 0 means reset, 1 means normal operation.
 */
static void fd_do_reset(struct fd_dev *fd, int hw_reset)
{
	if (hw_reset) {
		/* clear RSTS_RST_FMC bit, set  RSTS_RST_CORE bit*/
		fd_writel(fd, FD_RSTR_LOCK_W(0xdead) | FD_RSTR_RST_CORE_MASK,
		       FD_REG_RSTR);
		udelay(10000);
		fd_writel(fd, FD_RSTR_LOCK_W(0xdead) | FD_RSTR_RST_CORE_MASK
		       | FD_RSTR_RST_FMC_MASK, FD_REG_RSTR);
		/* TPS3307 supervisor needs time to de-assert master reset */
		msleep(600);
		return;
	}

	/* clear RSTS_RST_CORE bit, set RSTS_RST_FMC bit */
	fd_writel(fd, FD_RSTR_LOCK_W(0xdead) | FD_RSTR_RST_FMC_MASK,
		  FD_REG_RSTR);
	udelay(1000);
	fd_writel(fd, FD_RSTR_LOCK_W(0xdead) | FD_RSTR_RST_FMC_MASK
	       | FD_RSTR_RST_CORE_MASK, FD_REG_RSTR);
	udelay(1000);
}

/* Some init procedures to be intermixed with subsystems */
int fd_gpio_defaults(struct fd_dev *fd)
{
	fd_gpio_dir(fd, FD_GPIO_TRIG_INTERNAL, FD_GPIO_OUT);
	fd_gpio_set(fd, FD_GPIO_TRIG_INTERNAL);

	fd_gpio_set(fd, FD_GPIO_OUTPUT_MASK);
	fd_gpio_dir(fd, FD_GPIO_OUTPUT_MASK, FD_GPIO_OUT);

	fd_gpio_dir(fd, FD_GPIO_TERM_EN, FD_GPIO_OUT);
	fd_gpio_clr(fd, FD_GPIO_TERM_EN);
	return 0;
}

int fd_reset_again(struct fd_dev *fd)
{
	unsigned long j;

	/* Reset the FD core once we have proper reference/TDC clocks */
	fd_do_reset(fd, 0 /* not hw */);

	j = jiffies + 2 * HZ;
	while (time_before(jiffies, j)) {
		if (fd_readl(fd, FD_REG_GCR) & FD_GCR_DDR_LOCKED)
			break;
		msleep(10);
	}
	if (time_after_eq(jiffies, j)) {
		dev_err(&fd->pdev->dev,
			"%s: timeout waiting for GCR lock bit\n", __func__);
		return -EIO;
	}

	fd_do_reset(fd, 0 /* not hw */);
	return 0;
}

/* This structure lists the various subsystems */
struct fd_modlist {
	char *name;
	int (*init)(struct fd_dev *);
	void (*exit)(struct fd_dev *);
};


#define SUBSYS(x) { #x, fd_ ## x ## _init, fd_ ## x ## _exit }
static struct fd_modlist mods[] = {
	SUBSYS(spi),
	SUBSYS(gpio),
	SUBSYS(pll),
	SUBSYS(onewire),
	{"gpio-default", fd_gpio_defaults},
	{"reset-again", fd_reset_again},
	SUBSYS(acam),
	SUBSYS(time),
	SUBSYS(zio),
};



static int fd_resource_validation(struct platform_device *pdev)
{
	struct resource *r;

	r = platform_get_resource(pdev, IORESOURCE_IRQ, FD_IRQ);
	if (!r) {
		dev_err(&pdev->dev,
			"The Fine-Delay needs an interrupt number\n");
		return -ENXIO;
	}

	r = platform_get_resource(pdev, IORESOURCE_MEM, FD_MEM_BASE);
	if (!r) {
		dev_err(&pdev->dev,
			"The Fine-Delay needs base address\n");
		return -ENXIO;
	}

	return 0;
}

#define FD_FMC_NAME "FmcDelay1ns4cha"

static bool fd_fmc_slot_is_valid(struct fd_dev *fd)
{
	int ret;
	void *fru = NULL;
	char *fmc_name = NULL;

	if (!fmc_slot_fru_valid(fd->slot)) {
		dev_err(&fd->pdev->dev, "Can't identify FMC card: invalid FRU\n");
		return -EINVAL;
	}

	fru = kmalloc(FRU_SIZE_MAX, GFP_KERNEL);
	if (!fru)
		return -ENOMEM;

	ret = fmc_slot_eeprom_read(fd->slot, fru, 0x0, FRU_SIZE_MAX);
	if (ret != FRU_SIZE_MAX) {
		dev_err(&fd->pdev->dev, "Failed to read FRU header\n");
		goto err;
	}

	fmc_name = fru_get_product_name(fru);
	ret = strcmp(fmc_name, FD_FMC_NAME);
	if (ret) {
		dev_err(&fd->pdev->dev,
			"Invalid FMC card: expectd '%s', found '%s'\n",
			FD_FMC_NAME, fmc_name);
		goto err;
	}

	kfree(fmc_name);
	kfree(fru);

	return true;
err:
	kfree(fmc_name);
	kfree(fru);
	return false;
}

static int fd_endianess(struct fd_dev *fd)
{
	uint32_t signature;

	signature = ioread32(fd->fd_regs_base + FD_REG_IDR);
	if (signature == FD_MAGIC_FPGA)
		return 0;
	signature = ioread32be(fd->fd_regs_base + FD_REG_IDR);
	if (signature == FD_MAGIC_FPGA)
		return 1;
	return -1;
}
static int fd_memops_detect(struct fd_dev *fd)
{
	int ret;

	ret = fd_endianess(fd);
	if (ret < 0) {
		dev_err(&fd->pdev->dev, "Failed to detect endianess\n");
		return -EINVAL;
	}

	if (ret) {
		fd->memops.read = ioread32be;
		fd->memops.write = iowrite32be;
	} else {
		fd->memops.read = ioread32;
		fd->memops.write = iowrite32;
	}

	return 0;
}

/* probe and remove are called by the FMC bus core */
int fd_probe(struct platform_device *pdev)
{
	struct fd_modlist *m;
	struct fd_dev *fd;
	struct device *dev = &pdev->dev;
	int i, ret, ch, err, slot_nr;
	struct resource *r;

	err = fd_resource_validation(pdev);
	if (err)
		return err;

	fd = devm_kzalloc(&pdev->dev, sizeof(*fd), GFP_KERNEL);
	if (!fd)
		return -ENOMEM;

	platform_set_drvdata(pdev, fd);
	fd->pdev = pdev;
	fd->verbose = fd_verbose;
	r = platform_get_resource(pdev, IORESOURCE_MEM, FD_MEM_BASE);
	fd->fd_regs_base = ioremap(r->start, resource_size(r));
	fd->fd_owregs_base = fd->fd_regs_base + 0x500;
	spin_lock_init(&fd->lock);
	err = fd_memops_detect(fd);
	if (err)
		goto err_memops;

	slot_nr = fd_readl(fd, FD_REG_FMC_SLOT_ID) + 1;
	fd->slot = fmc_slot_get(pdev->dev.parent->parent, slot_nr);
	if (IS_ERR(fd->slot)) {
		dev_err(&fd->pdev->dev,
			"Can't find FMC slot %d err: %ld\n",
			slot_nr, PTR_ERR(fd->slot));
		goto out_fmc;
	}

	if (!fmc_slot_present(fd->slot)) {
		dev_err(&fd->pdev->dev,
			"Can't identify FMC card: missing card\n");
		goto out_fmc_pre;
	}

	if (strcmp(fmc_slot_eeprom_type_get(fd->slot), FA_EEPROM_TYPE)) {
		dev_warn(&fd->pdev->dev,
			 "use non standard EERPOM type \"%s\"\n",
			 FA_EEPROM_TYPE);
		err = fmc_slot_eeprom_type_set(fd->slot, FA_EEPROM_TYPE);
		if (err) {
			dev_err(&fd->pdev->dev,
				"Failed to change EEPROM type to \"%s\"",
				FA_EEPROM_TYPE);
			goto out_fmc_eeprom;
		}
	}

	if(!fd_fmc_slot_is_valid(fd))
		goto out_fmc_err;

	/* Retrieve calibration from the eeprom, and validate */
	ret = fd_handle_calibration(fd, NULL);
	if (ret < 0)
		return ret;

	/* First, hardware reset */
	fd_do_reset(fd, 1);

	/* init all subsystems */
	for (i = 0, m = mods; i < ARRAY_SIZE(mods); i++, m++) {
		dev_dbg(dev, "%s: Calling init for \"%s\"\n", __func__,
			  m->name);
		ret = m->init(fd);
		if (ret < 0) {
			dev_err(dev, "%s: error initializing %s\n", __func__,
				m->name);
			goto err;
		}
	}

	/* Finally, enable the input emgine */
	ret = fd_irq_init(fd);
	if (ret < 0)
		goto err;

	ret = device_create_bin_file(&fd->pdev->dev, &dev_attr_eeprom);
	if (ret) {
		dev_warn(&fd->pdev->dev,
			 "Cannot create sysfs attribute, use default calibration data\n");
	}

	if (0) {
		struct timespec ts1, ts2, ts3;
		/* Temporarily, test the time stuff */
		fd_time_set(fd, NULL, NULL);
		fd_time_get(fd, NULL, &ts1);
		msleep(100);
		fd_time_get(fd, NULL, &ts2);
		getnstimeofday(&ts3);
		printk("%li.%li\n%li.%li\n%li.%li\n",
		       ts1.tv_sec, ts1.tv_nsec,
		       ts2.tv_sec, ts2.tv_nsec,
		       ts3.tv_sec, ts3.tv_nsec);
	}
	set_bit(FD_FLAG_INITED, &fd->flags);

	/* set all output enable stages */
	for (ch = 1; ch <= FD_CH_NUMBER; ch++)
		fd_gpio_set(fd, FD_GPIO_OUTPUT_EN(ch));

	return 0;

err:
	while (--m, --i >= 0)
		if (m->exit)
			m->exit(fd);
out_fmc_err:
out_fmc_eeprom:
out_fmc_pre:
	fmc_slot_put(fd->slot);
out_fmc:
err_memops:
	iounmap(fd->fd_regs_base);
	devm_kfree(&pdev->dev, fd);
	platform_set_drvdata(pdev, NULL);

	return ret;
}

int fd_remove(struct platform_device *pdev)
{
	struct fd_modlist *m;
	struct fd_dev *fd = platform_get_drvdata(pdev);
	int i = ARRAY_SIZE(mods);

	if (!test_bit(FD_FLAG_INITED, &fd->flags)) /* FIXME: ditch this */
		return 0; /* No init, no exit */

	device_remove_bin_file(&fd->pdev->dev, &dev_attr_eeprom);

	fd_irq_exit(fd);
	while (--i >= 0) {
		m = mods + i;
		if (m->exit)
			m->exit(fd);
	}
	iounmap(fd->fd_regs_base);

	fmc_slot_put(fd->slot);

	return 0;
}

static const struct platform_device_id fd_id[] = {
	{
		.name = "fmc-fdelay-tdc",
		.driver_data = FD_VER_TDC,
	},
	/* TODO we should support different version */
};


static struct platform_driver fd_platform_driver = {
	.driver = {
		.name = KBUILD_MODNAME,
	},
	.probe = fd_probe,
	.remove = fd_remove,
	.id_table = fd_id,
};


static int fd_init(void)
{
	int ret;

	ret = fd_zio_register();
	if (ret < 0)
		return ret;
	ret = platform_driver_register(&fd_platform_driver);
	if (ret < 0) {
		fd_zio_unregister();
		return ret;
	}
	return 0;
}

static void fd_exit(void)
{
	platform_driver_unregister(&fd_platform_driver);
	fd_zio_unregister();
}

module_init(fd_init);
module_exit(fd_exit);

MODULE_VERSION(VERSION);
MODULE_LICENSE("GPL and additional rights"); /* LGPL */

ADDITIONAL_VERSIONS;
