// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/mfd/core.h>

enum fd_spec_dev_offsets {
	FD_SPEC_FDT_MEM_START = 0x0000E000,
	FD_SPEC_FDT_MEM_END = 0x0000E1FF,
};

/* MFD devices */
enum spec_fpga_mfd_devs_enum {
	FD_SPEC_MFD_FDT = 0,
};

static struct resource fd_spec_fdt_res[] = {
	{
		.name = "fmc-fdelay-tdc-mem",
		.flags = IORESOURCE_MEM,
		.start = FD_SPEC_FDT_MEM_START,
		.end = FD_SPEC_FDT_MEM_END,
	}, {
		.name = "fmc-fdelay-tdc-irq",
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		.start = 0,
		.end = 0,
	},
};

static const struct mfd_cell fd_spec_mfd_devs[] = {
	[FD_SPEC_MFD_FDT] = {
		.name = "fmc-fdelay-tdc",
		.platform_data = NULL,
		.pdata_size = 0,
		.num_resources = ARRAY_SIZE(fd_spec_fdt_res),
		.resources = fd_spec_fdt_res,
	},
};


static int fd_spec_probe(struct platform_device *pdev)
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
			       fd_spec_mfd_devs,
			       ARRAY_SIZE(fd_spec_mfd_devs),
			       rmem, irq, NULL);
}

static int fd_spec_remove(struct platform_device *pdev)
{
	mfd_remove_devices(&pdev->dev);

	return 0;
}

/**
 * List of supported platform
 */
enum fd_spec_version {
	FD_SPEC_VER = 0,
};

static const struct platform_device_id fd_spec_id_table[] = {
	{
		.name = "fdelay-spec",
		.driver_data = FD_SPEC_VER,
	}, {
		.name = "id:000010DC574ECAFE",
		.driver_data = FD_SPEC_VER,
	}, {
		.name = "id:000010dc574ecafe",
		.driver_data = FD_SPEC_VER,
	},
	{},
};

static struct platform_driver fd_spec_driver = {
	.driver = {
		.name = "fdelay-spec",
		.owner = THIS_MODULE,
	},
	.id_table = fd_spec_id_table,
	.probe = fd_spec_probe,
	.remove = fd_spec_remove,
};
module_platform_driver(fd_spec_driver);

MODULE_AUTHOR("Federico Vaga <federico.vaga@cern.ch>");
MODULE_LICENSE("GPL");
MODULE_VERSION(VERSION);
MODULE_DESCRIPTION("Driver for the SPEC Fine-Delay");
MODULE_DEVICE_TABLE(platform, fd_spec_id_table);

MODULE_SOFTDEP("pre: spec_fmc_carrier fmc-fine-delay");
