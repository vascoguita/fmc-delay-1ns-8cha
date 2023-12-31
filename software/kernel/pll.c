// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include <linux/kernel.h>
#include <linux/io.h>
#include <linux/delay.h>
#include <linux/jiffies.h>
#include "fine-delay.h"
#include "hw/pll_config.h" /* the table to be written */

const struct ad9516_reg __9516_regs[] = {
	{0x0000, 0x99}, /* Config SPI */
	{0x0001, 0x00},
	{0x0002, 0x10},
	{0x0003, 0xC3},
	{0x0004, 0x00},
	/* PLL */
	{0x0010, 0x7C}, /* PFD and charge pump */
	{0x0011, 0x05}, /* R divider (1) */
	{0x0012, 0x00}, /* R divider (2) */
	{0x0013, 0x0C}, /* A counter */
	{0x0014, 0x12}, /* B counter (1) */
	{0x0015, 0x00}, /* B counter (2) */
	{0x0016, 0x05}, /* PLL control (1) */
	{0x0017, 0xb4}, /* PLL control (2)  PLL_STATUS = Lock Detect */
	{0x0018, 0x07}, /* PLL control (3) */
	{0x0019, 0x00}, /* PLL control (4) */
	{0x001A, 0x00}, /* PLL control (5) */
	{0x001B, 0xE0}, /* PLL control (6) */
	{0x001C, 0x02}, /* PLL control (7) */
	{0x001D, 0x00}, /* PLL control (8) */
	{0x001E, 0x00}, /* PLL control (9) */
	{0x001F, 0x0E}, /* PLL readback */
	/* Fine Delay */
	{0x00A0, 0x01}, /* OUT6 Delay bypass */
	{0x00A1, 0x00}, /* OUT6 Delay full-scale */
	{0x00A2, 0x00}, /* OUT6 Delay fraction */
	{0x00A3, 0x01}, /* OUT7 Delay bypass */
	{0x00A4, 0x00}, /* OUT7 Delay full-scale */
	{0x00A5, 0x00}, /* OUT7 Delay fraction */
	{0x00A6, 0x01}, /* OUT8 Delay bypass */
	{0x00A7, 0x00}, /* OUT8 Delay full-scale */
	{0x00A8, 0x00}, /* OUT8 Delay fraction */
	{0x00A9, 0x01}, /* OUT9 Delay bypass */
	{0x00AA, 0x00}, /* OUT9 Delay full-scale */
	{0x00AB, 0x00}, /* OUT9 Delay fraction */
	/* LVPECL */
	{0x00F0, 0x08}, /* OUT0 */
	{0x00F1, 0x08}, /* OUT1 */
	{0x00F2, 0x08}, /* OUT2 */
	{0x00F3, 0x18}, /* OUT3, inverted */
	{0x00F4, 0x00}, /* OUT4 */
	{0x00F5, 0x08}, /* OUT5 */
	/* LVDS/CMOS */
	{0x0140, 0x5A}, /* OUT6 */
	{0x0141, 0x5A}, /* OUT7 */
	{0x0142, 0x5B}, /* OUT8 */
	{0x0143, 0x42}, /* OUT9 */
	/* LVPECL Channel divider */
	{0x0190, 0x00}, /* Divider 0 (1) */
	{0x0191, 0x80}, /* Divider 0 (2) */
	{0x0192, 0x00}, /* Divider 0 (3) */
	{0x0193, 0x00}, /* Divider 1 (1) */
	{0x0194, 0x80}, /* Divider 1 (2) */
	{0x0195, 0x00}, /* Divider 1 (3) */
	{0x0196, 0xFF}, /* Divider 2 (1) */
	{0x0197, 0x00}, /* Divider 2 (2) */
	{0x0198, 0x00}, /* Divider 2 (3) */
	/* LVDS/CMOS Channel divider */
	{0x0199, 0x33}, /* Divider 3 (1) */
	{0x019A, 0x00}, /* Divider 3 (2) */
	{0x019B, 0x11}, /* Divider 3 (3) */
	{0x019C, 0x20}, /* Divider 3 (4) */
	{0x019D, 0x00}, /* Divider 3 (5) */
	{0x019E, 0x00}, /* Divider 4 (1) */
	{0x019F, 0x00}, /* Divider 4 (2) */
	{0x01A0, 0x11}, /* Divider 4 (3) */
	{0x01A1, 0x20}, /* Divider 4 (4) */
	{0x01A2, 0x00}, /* Divider 4 (5) */
	{0x01A3, 0x00},
	/* VCO Divider and CLK Input */
	{0x01E0, 0x04}, /* VCO divider VCODIV = 6 */
	{0x01E1, 0x02}, /* Input Clock */
	/* System */
	{0x0230, 0x00}, /* Power down and sync */
	{0x0231, 0x00},
	/* Update All registers */
	{0x0232, 0x00}, /* Update All registers */
};

const unsigned int __9516_regs_n = ARRAY_SIZE(__9516_regs);

static int pll_writel(struct fd_dev *fd, int val, int reg)
{
	return fd_spi_xfer(fd, FD_CS_PLL, 24, (reg << 8) | val, NULL);
}

static int pll_readl(struct fd_dev *fd, int reg)
{
	uint32_t ret;
	int err;

	err = fd_spi_xfer(fd, FD_CS_PLL, 24, (reg << 8) | (1 << 23), &ret);
	if (err < 0)
		return err;
	return ret & 0xff;
}

int fd_pll_init(struct fd_dev *fd)
{
	int i;
	unsigned long j;
	const struct ad9516_reg *r;
	struct device *dev = &fd->pdev->dev;

	if (pll_writel(fd, 0x99, 0x000) < 0)
		goto out;
	if (pll_writel(fd, 0x01, 0x232) < 0)
		goto out;
	i = pll_readl(fd, 0x003);
	if (i < 0)
		goto out;
	if (i != 0xc3) {
		dev_err(dev, "Error in PLL communication\n");
		dev_err(dev, "   (got 0x%x, expected 0xc3)\n", i);
		return -EIO;
	}

	/* Write the magic config */
	for (i = 0, r = __9516_regs; i < __9516_regs_n; i++, r++) {
		if (pll_writel(fd, r->val, r->reg) < 0) {
			dev_err(dev, "Error in configuring PLL (step %i)\n", i);
			return -EIO;
		}
	}

	if (pll_writel(fd, 0x01, 0x232) < 0)
		goto out;

	/* Wait for it to lock */
	j = jiffies + HZ / 2;
	while (jiffies < j) {
		i = pll_readl(fd, 0x1f);
		if (i < 0)
			return -EIO;
		if (i & 1)
			break;
		msleep(1);
	}
	if (!(i & 1))
		return -ETIMEDOUT;

	/*
	 * Synchronize the phase of all clock outputs
	 * (this is critical for the accuracy!)
	 */

	if (pll_writel(fd, 0x01, 0x230) < 0)
		goto out;
	if (pll_writel(fd, 0x01, 0x232) < 0)
		goto out;
	if (pll_writel(fd, 0x00, 0x230) < 0)
		goto out;
	if (pll_writel(fd, 0x01, 0x232) < 0)
		goto out;

	return 0;

out:
	dev_err(dev, "Error in SPI communication\n");
	return -EIO;
}

void fd_pll_exit(struct fd_dev *fd)
{
	/* nothing to do */
}
