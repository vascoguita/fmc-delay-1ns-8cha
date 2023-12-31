// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include <linux/io.h>
#include <linux/time.h>
#include <linux/spinlock.h>
#include "fine-delay.h"
#include "hw/fd_main_regs.h"

/* If fd_time is not null, use it. if ts is not null, use it, else current */

#if LINUX_VERSION_CODE < KERNEL_VERSION(5,6,0)
int fd_time_set(struct fd_dev *fd, struct fd_time *t, struct timespec *ts)
{
	struct timespec localts;
#else
int fd_time_set(struct fd_dev *fd, struct fd_time *t, struct timespec64 *ts)
{
	struct timespec64 localts;
#endif
	uint32_t tcr, gcr;
	unsigned long flags;

	spin_lock_irqsave(&fd->lock, flags);

	gcr = fd_readl(fd, FD_REG_GCR);
	fd_writel(fd, 0, FD_REG_GCR); /* zero the GCR while setting time */
	if (t) {
		fd_writel(fd, t->utc >> 32, FD_REG_TM_SECH);
		fd_writel(fd, t->utc & 0xffffffff, FD_REG_TM_SECL);
		fd_writel(fd, t->coarse, FD_REG_TM_CYCLES);
	} else {
		if (!ts) {
			/* no caller-provided time: use Linux timer */
			ts = &localts;
#if LINUX_VERSION_CODE < KERNEL_VERSION(5,6,0)
			getnstimeofday(ts);
#else
			ktime_get_ts64(ts);
#endif
		}
		fd_writel(fd, GET_HI32(ts->tv_sec), FD_REG_TM_SECH);
		fd_writel(fd, (int32_t)ts->tv_sec, FD_REG_TM_SECL);
		fd_writel(fd, ts->tv_nsec >> 3, FD_REG_TM_CYCLES);
	}

	tcr = fd_readl(fd, FD_REG_TCR);
	fd_writel(fd, tcr | FD_TCR_SET_TIME, FD_REG_TCR);
	fd_writel(fd, gcr, FD_REG_GCR); /* Restore GCR */

	spin_unlock_irqrestore(&fd->lock, flags);
	return 0;
}

/* If fd_time is not null, use it. Otherwise use ts */
#if LINUX_VERSION_CODE < KERNEL_VERSION(5,6,0)
int fd_time_get(struct fd_dev *fd, struct fd_time *t, struct timespec *ts)
#else
int fd_time_get(struct fd_dev *fd, struct fd_time *t, struct timespec64 *ts)
#endif
{
	uint32_t tcr, h, l, c;
	unsigned long flags;

	spin_lock_irqsave(&fd->lock, flags);
	tcr = fd_readl(fd, FD_REG_TCR);
	fd_writel(fd, tcr | FD_TCR_CAP_TIME, FD_REG_TCR);
	h = fd_readl(fd, FD_REG_TM_SECH);
	l = fd_readl(fd, FD_REG_TM_SECL);
	c = fd_readl(fd, FD_REG_TM_CYCLES);
	spin_unlock_irqrestore(&fd->lock, flags);

	if (t) {
		t->utc = ((uint64_t)h << 32) | l;
		t->coarse = c;
	}
	if (ts) {
		ts->tv_sec = ((uint64_t)h << 32) | l;
		ts->tv_nsec = c * 8;
	}
	return 0;
}

int fd_time_init(struct fd_dev *fd)
{
#if LINUX_VERSION_CODE < KERNEL_VERSION(5,6,0)
	struct timespec ts = {0,0};
#else
	struct timespec64 ts = {0,0};
#endif

	/* Set the time to zero, so internal stuff resyncs */
	return fd_time_set(fd, NULL, &ts);
}

void fd_time_exit(struct fd_dev *fd)
{
	/* nothing to do */
}

