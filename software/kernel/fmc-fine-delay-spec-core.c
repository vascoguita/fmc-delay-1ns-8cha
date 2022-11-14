// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */

#include <linux/module.h>
#include <linux/mod_devicetable.h>
#include <linux/platform_device.h>
#include <linux/mfd/core.h>

enum fd_spec_dev_offsets {
	FD_SPEC_FDT_MEM_START = 0x0000E000,
	FD_SPEC_FDT_MEM_END = 0x0000E1FF,
};

static int fd_spec_probe(struct platform_device *pdev)
{
	static struct resource fd_spec_fdt_res[] = {
		{
			.name = "fmc-fdelay-tdc-mem",
			.flags = IORESOURCE_MEM,
		},
		{
			.name = "fmc-fdelay-tdc-irq",
			.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		}
	};
	struct platform_device_info pdevinfo = {
		.parent = &pdev->dev,
		.name = "fmc-fdelay-tdc",
		.id = PLATFORM_DEVID_AUTO,
		.res = fd_spec_fdt_res,
		.num_res = ARRAY_SIZE(fd_spec_fdt_res),
		.data = NULL,
		.size_data = 0,
		.dma_mask = 0,
	};
	struct platform_device *pdev_child;
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

	fd_spec_fdt_res[0].parent = rmem;
	fd_spec_fdt_res[0].start = rmem->start + FD_SPEC_FDT_MEM_START;
	fd_spec_fdt_res[0].end = rmem->start + FD_SPEC_FDT_MEM_END;
	fd_spec_fdt_res[1].start = irq;


	pdev_child = platform_device_register_full(&pdevinfo);
	if (IS_ERR(pdev_child))
		return PTR_ERR(pdev_child);
	platform_set_drvdata(pdev, pdev_child);
	return 0;
}

static int fd_spec_remove(struct platform_device *pdev)
{
	struct platform_device *pdev_child = platform_get_drvdata(pdev);

	platform_device_unregister(pdev_child);

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
		.name = "id:000010DC574F0001",
		.driver_data = FD_SPEC_VER,
	}, {
		.name = "id:000010dc574f0001",
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
