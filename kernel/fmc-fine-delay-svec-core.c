// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/mfd/core.h>

enum fd_svec_dev_offsets {
	FD_SVEC_FDT1_MEM_START = 0x0000E000,
	FD_SVEC_FDT1_MEM_END = 0x0000E1FF,
	FD_SVEC_FDT2_MEM_START = 0x0001E000,
	FD_SVEC_FDT2_MEM_END = 0x0001E1FF,
};

/* MFD devices */
enum svec_fpga_mfd_devs_enum {
	FD_SVEC_MFD_FDT1 = 0,
	FD_SVEC_MFD_FDT2,
};

static struct resource fd_svec_fdt1_res[] = {
	{
		.name = "fmc-fdelay-tdc-mem.1",
		.flags = IORESOURCE_MEM,
		.start = FD_SVEC_FDT1_MEM_START,
		.end = FD_SVEC_FDT1_MEM_END,
	}, {
		.name = "fmc-fdelay-tdc-irq.1",
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		.start = 0,
		.end = 0,
	},
};
static struct resource fd_svec_fdt2_res[] = {
	{
		.name = "fmc-fdelay-tdc-mem.2",
		.flags = IORESOURCE_MEM,
		.start = FD_SVEC_FDT2_MEM_START,
		.end = FD_SVEC_FDT2_MEM_END,
	}, {
		.name = "fmc-fdelay-tdc-irq.2",
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		.start = 1,
		.end = 1,
	},
};

static const struct mfd_cell fd_svec_mfd_devs[] = {
	[FD_SVEC_MFD_FDT1] = {
		.name = "fmc-fdelay-tdc",
		.platform_data = NULL,
		.pdata_size = 0,
		.num_resources = ARRAY_SIZE(fd_svec_fdt1_res),
		.resources = fd_svec_fdt1_res,
	},
	[FD_SVEC_MFD_FDT2] = {
		.name = "fmc-fdelay-tdc",
		.platform_data = NULL,
		.pdata_size = 0,
		.num_resources = ARRAY_SIZE(fd_svec_fdt2_res),
		.resources = fd_svec_fdt2_res,
	},
};


static int fd_svec_probe(struct platform_device *pdev)
{
	struct resource *rmem;
	int irq;

	rmem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (!rmem) {
		dev_err(&pdev->dev, "Missing memory resource\n");
		return -EINVAL;
	}

	irq = platform_get_irq(pdev, 0);
	if (irq < 0) {
		dev_err(&pdev->dev, "Missing IRQ number\n");
		return -EINVAL;
	}

	/*
	 * We know that this design uses the HTVIC IRQ controller.
	 * This IRQ controller has a linear mapping, so it is enough
	 * to give the first one as input
	 */

	return mfd_add_devices(&pdev->dev, PLATFORM_DEVID_AUTO,
			       fd_svec_mfd_devs,
			       ARRAY_SIZE(fd_svec_mfd_devs),
			       rmem, irq, NULL);
}

static int fd_svec_remove(struct platform_device *pdev)
{
	mfd_remove_devices(&pdev->dev);

	return 0;
}

/**
 * List of supported platform
 */
enum fd_svec_version {
	FD_SVEC_VER = 0,
};

static const struct platform_device_id fd_svec_id_table[] = {
	{
		.name = "fdelay-svec",
		.driver_data = FD_SVEC_VER,
	}, {
		.name = "id:000010DC574ECAFE",
		.driver_data = FD_SVEC_VER,
	}, {
		.name = "id:000010dc574ecafe",
		.driver_data = FD_SVEC_VER,
	},
	{},
};

static struct platform_driver fd_svec_driver = {
	.driver = {
		.name = "fdelay-svec",
		.owner = THIS_MODULE,
	},
	.id_table = fd_svec_id_table,
	.probe = fd_svec_probe,
	.remove = fd_svec_remove,
};
module_platform_driver(fd_svec_driver);

MODULE_AUTHOR("Federico Vaga <federico.vaga@cern.ch>");
MODULE_LICENSE("GPL");
MODULE_VERSION(VERSION);
MODULE_DESCRIPTION("Driver for the SVEC Double Fine-Delay");
MODULE_DEVICE_TABLE(platform, fd_svec_id_table);

MODULE_SOFTDEP("pre: svec_fmc_carrier fmc-fine-delay");
