// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright CERN 2020
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */

#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/debugfs.h>
#include "fine-delay.h"
#include "hw/pll_config.h"

static void fd_spi_seq_printf(struct fd_dev *fd, int reg, struct seq_file *s)
{
	uint32_t rx;
	int err;

	err = fd_spi_xfer(fd, FD_CS_PLL, 24, (reg << 8) | BIT(23), &rx);
	rx &= 0xFF; /* the value is 8bit */
	if (err)
		seq_printf(s, "%03xh    read failure!\n",
			   reg);
	else
		seq_printf(s, "%03xh    0x%02x\n",
			   reg, rx);
}

static int fd_regdump_pll_seq_read(struct seq_file *s, void *data)
{
	struct fd_dev *fd = s->private;
	int i;

	seq_printf(s, "PLL SPI registers\n");
	seq_printf(s, "Address   Data\n");
	for (i = 0; i < __9516_regs_n; ++i)
		fd_spi_seq_printf(fd, __9516_regs[i].reg, s);

	return 0;
}


static int fd_regdump_pll_open(struct inode *inode, struct file *file)
{
	return single_open(file, fd_regdump_pll_seq_read, inode->i_private);
}


static const struct file_operations fd_regdump_pll_ops = {
	.owner = THIS_MODULE,
	.open = fd_regdump_pll_open,
	.read = seq_read,
	.llseek = seq_lseek,
	.release = single_release,
};


int fd_debug_init(struct fd_dev *fd)
{
	int err;

	fd->dbg_dir = debugfs_create_dir(dev_name(&fd->pdev->dev), NULL);
	if (IS_ERR_OR_NULL(fd->dbg_dir)) {
		err = PTR_ERR(fd->dbg_dir);
		dev_err(&fd->pdev->dev,
			"Cannot create debugfs directory \"%s\" (%d)\n",
			dev_name(&fd->pdev->dev), err);
		return err;
	}

	fd->dbg_reg_spi_pll = debugfs_create_file("spi-regs-pll", 0444,
						  fd->dbg_dir, fd,
						  &fd_regdump_pll_ops);
	if (IS_ERR_OR_NULL(fd->dbg_reg_spi_pll)) {
		dev_warn(&fd->pdev->dev,
			 "Cannot create regdump PLL debugfs file\n");
	}

	return 0;
}


void fd_debug_exit(struct fd_dev *fd)
{
	debugfs_remove_recursive(fd->dbg_dir);
}
