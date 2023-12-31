// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/timer.h>
#include <linux/jiffies.h>
#include <linux/bitops.h>
#include <linux/spinlock.h>
#include <linux/io.h>

#include <linux/zio.h>
#include <linux/zio-buffer.h>
#include <linux/zio-trigger.h>

#include "fine-delay.h"
#include "hw/fd_main_regs.h"
#include "hw/fd_channel_regs.h"

static int fd_sw_fifo_len = FD_SW_FIFO_LEN;
module_param_named(fifo_len, fd_sw_fifo_len, int, 0444);

/* Subtract an offset (used for the input timestamp) */
static void fd_ts_sub(struct fd_time *t, uint64_t pico)
{
	uint32_t coarse, frac;

	/* FIXME: we really need to pre-convert pico to internal repres. */
	fd_split_pico(pico, &coarse, &frac);
	if (t->frac >= frac) {
		t->frac -= frac;
	} else {
		t->frac = 4096 + t->frac - frac;
		coarse++;
	}
	if (t->coarse >= coarse) {
		t->coarse -= coarse;
	} else {
		t->coarse = 125*1000*1000 + t->coarse - coarse;
		t->utc--;
	}
}

static void fd_ts_add(struct fd_time *t, int64_t pico)
{
	uint32_t coarse, frac;

	/* FIXME: we really need to pre-convert pico to internal repres. */
	if (pico < 0) {
		fd_ts_sub(t, -pico);
		return;
	}

	fd_split_pico(pico, &coarse, &frac);
	t->frac += frac;
	t->coarse += coarse;
	if (t->frac >= 4096) {
		t->frac -= 4096;
		t->coarse++;
	}
	if (t->coarse >= 125*1000*1000) {
		t->coarse -= 125*1000*1000;
		t->utc++;
	}
}

static inline void fd_normalize_time(struct fd_dev *fd, struct fd_time *t)
{
	/* The coarse count may be negative, because of how it works */
	if (t->coarse & (1<<27)) { // coarse is 28 bits
		/* we may get 0xfff.ffef..0xffff.ffff -- 125M == 0x773.5940 */
		t->coarse += 125000000;
		t->coarse &= 0xfffffff;
		t->utc--;
	} else if(t->coarse >= 125000000) {
		t->coarse -= 125000000;
		t->utc++;
	}

	fd_ts_add(t, fd->calib.tdc_zero_offset);
	fd_ts_add(t, fd->tdc_user_offset);
}


/* This is called from outside, too */
int fd_read_sw_fifo(struct fd_dev *fd, struct zio_channel *chan)
{
	struct zio_control *ctrl;
	struct zio_ti *ti = chan->cset->ti;
	uint32_t *v;
	int i, j;
	struct fd_time t, *tp;
	unsigned long flags;

	if (fd->sw_fifo.tail == fd->sw_fifo.head)
		return -EAGAIN;
	/*
	 * Proceed even if no active block is there. The buffer may be
	 * full, but we need to keep the trigger armed for next time,
	 * so deal with data and return success. If we -EAGAIN when
	 * !chan->active_block is null, we'll miss an irq to restar the loop.
	 */

	/* Copy the sample to a local variable, to release the lock soon */
	spin_lock_irqsave(&fd->lock, flags);
	i = fd->sw_fifo.tail % fd_sw_fifo_len;
	t = fd->sw_fifo.t[i];
	fd->sw_fifo.tail++;
	spin_unlock_irqrestore(&fd->lock, flags);

	fd_normalize_time(fd, &t);

	/* Write the timestamp in the trigger, it will reach the control */
	ti->tstamp.tv_sec = t.utc;
	ti->tstamp.tv_nsec = t.coarse * 8;
	ti->tstamp_extra = t.frac;

	/*
	 * This is different than it was. We used to fill the active block,
	 * but now zio copies chan->current_ctrl at a later time, so we
	 * must fill _those_ attributes instead
	 */
	/* The input data is written to attribute values in the active block. */
	ctrl = chan->current_ctrl;
	v = ctrl->attr_channel.ext_val;
	v[FD_ATTR_TDC_UTC_H]	= t.utc >> 32;
	v[FD_ATTR_TDC_UTC_L]	= t.utc;
	v[FD_ATTR_TDC_COARSE]	= t.coarse;
	v[FD_ATTR_TDC_FRAC]	= t.frac;
	v[FD_ATTR_TDC_SEQ]	= t.seq_id;
	v[FD_ATTR_TDC_CHAN]	= t.channel;
	v[FD_ATTR_TDC_FLAGS]	= fd->tdc_flags;
	v[FD_ATTR_TDC_OFFSET]	= fd->calib.tdc_zero_offset;
	v[FD_ATTR_TDC_USER_OFF]	= fd->tdc_user_offset;

	/* We also need a copy within the device, so sysfs can read it */
	memcpy(fd->tdc_attrs, v + FD_ATTR_DEV__LAST, sizeof(fd->tdc_attrs));

	if (ctrl->ssize == 0) /* normal TDC device: no data */
		return 0;

	/*
	 * If we are returning raw data in the payload, cluster as many
	 * samples as they fit, or as many as the fifo has. If a block is there.
	 */
	if (!chan->active_block)
		return 0;

	tp = chan->active_block->data;
	*tp++ = t; /* already normalized, above */

	for (j = 1; j < ctrl->nsamples; j++, tp++) {
		spin_lock_irqsave(&fd->lock, flags);
		if (fd->sw_fifo.tail == fd->sw_fifo.head) {
			spin_unlock_irqrestore(&fd->lock, flags);
			break;
		}
		i = fd->sw_fifo.tail % fd_sw_fifo_len;
		*tp = fd->sw_fifo.t[i];
		fd->sw_fifo.tail++;
		spin_unlock_irqrestore(&fd->lock, flags);
		fd_normalize_time(fd, tp);
	}
	ctrl->nsamples = j;
	chan->active_block->datalen = j * ctrl->ssize;
	return 0;
}

/* This is local: reads the hw fifo and stores to the sw fifo */
static int fd_read_hw_fifo(struct fd_dev *fd)
{
	uint32_t reg;
	struct fd_time *t;
	unsigned long flags;
	signed long diff;

	if ((fd_readl(fd, FD_REG_TSBCR) & FD_TSBCR_EMPTY))
		return -EAGAIN;

	spin_lock_irqsave(&fd->lock, flags);
	t = fd->sw_fifo.t;
	t += fd->sw_fifo.head % fd_sw_fifo_len;

	/* Fetch the fifo entry to registers, so we can read them */
	fd_writel(fd, FD_TSBR_ADVANCE_ADV, FD_REG_TSBR_ADVANCE);

	/* Read input data into the sofware fifo */
	t->utc = fd_readl(fd, FD_REG_TSBR_SECH) & 0xff;
	t->utc <<= 32;
	t->utc |= fd_readl(fd, FD_REG_TSBR_SECL);
	t->coarse = fd_readl(fd, FD_REG_TSBR_CYCLES) & 0xfffffff;
	reg = fd_readl(fd, FD_REG_TSBR_FID);
	t->frac = FD_TSBR_FID_FINE_R(reg);
	t->channel = FD_TSBR_FID_CHANNEL_R(reg);
	t->seq_id = FD_TSBR_FID_SEQID_R(reg);

	/* Then, increment head and make some checks */
	diff = fd->sw_fifo.head - fd->sw_fifo.tail;
	fd->sw_fifo.head++;
	if (diff >= fd_sw_fifo_len)
		fd->sw_fifo.tail += fd_sw_fifo_len / 2;
	spin_unlock_irqrestore(&fd->lock, flags);

	BUG_ON(diff < 0);
	if (diff >= fd_sw_fifo_len)
		dev_dbg(&fd->pdev->dev, "Fifo overflow: "
			 " dropped %i samples (%li -> %li == %li)\n",
			 fd_sw_fifo_len / 2,
			 fd->sw_fifo.tail, fd->sw_fifo.head, diff);

	return 0;
}

/*
 * We have a timer, used to poll for input samples, until the interrupt
 * is there. A timer duration of 0 selects the interrupt.
 */
static int fd_timer_period_ms = 0;
module_param_named(timer_ms, fd_timer_period_ms, int, 0444);

static int fd_timer_period_jiffies; /* converted from ms at init time */

/* This is an interrupt tasklet but can act as a timer */
static void fd_tlet(struct fd_dev *fd)
{
	struct zio_device *zdev = fd->zdev;
	struct zio_channel *chan = zdev->cset[0].chan;

	/* If we have no interrupt, read the hw fifo now */
	if (fd_timer_period_ms) {
		while (!fd_read_hw_fifo(fd))
			;
		mod_timer(&fd->fifo_timer, jiffies + fd_timer_period_jiffies);
	}

	/* FIXME: race condition */
	if (!test_bit(FD_FLAG_INPUT_READY, &fd->flags))
		return;

	/* there is an active block, try reading an accumulated sample */
	if (fd_read_sw_fifo(fd, chan) == 0) {
		clear_bit(FD_FLAG_INPUT_READY, &fd->flags);
		zio_trigger_data_done(chan->cset);
	}
}

static void fd_tlet_interrupt(unsigned long arg)
{
	struct fd_dev *fd = (void *)arg;
	fd_tlet(fd);
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,14,0)
static void fd_tlet_timer(struct timer_list *arg)
{
	struct fd_dev *fd = from_timer(fd, arg, fifo_timer);
	fd_tlet(fd);
}
#endif

/*
 * fd_irq_handler
 * NOTE: TS_BUF_NOTEMPTY interrupt is level sensitive, it is cleared when
 * you read the whole fifo buffer. It is useless to clear the interrupt
 * in EIC_ISR
 */
irqreturn_t fd_irq_handler(int irq, void *arg)
{
	struct fd_dev *fd = arg;

	if ((fd_readl(fd, FD_REG_TSBCR) & FD_TSBCR_EMPTY))
		goto out_unexpected; /* bah! */

	/*
	 * We must empty the fifo in hardware, and ack at this point.
	 * I used to disable_irq() and empty the fifo in the tasklet,
	 * but it doesn't work because the hw request is still pending
	 */
	while (!fd_read_hw_fifo(fd))
		;
	tasklet_schedule(&fd->tlet);

out_unexpected:

	return IRQ_HANDLED;
}

int fd_irq_init(struct fd_dev *fd)
{
	int rv;

	/* Check that the sw fifo size is a power of two */
	if (fd_sw_fifo_len & (fd_sw_fifo_len - 1)) {
		dev_err(&fd->pdev->dev,
			"fifo len must be a power of 2 (not %d = 0x%x)\n",
		        fd_sw_fifo_len, fd_sw_fifo_len);
		return -EINVAL;
	}

	fd->sw_fifo.t = kmalloc(fd_sw_fifo_len * sizeof(*fd->sw_fifo.t),
				GFP_KERNEL);
	if (!fd->sw_fifo.t)
		return -ENOMEM;

	/*
	 * According to the period, this can work with a timer (old way)
	 * or a custom tasklet (newer). Init both anyways, no harm is done.
	 */
	if (fd_timer_period_ms) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(4,14,0)
		setup_timer(&fd->fifo_timer, fd_tlet_interrupt, (unsigned long)fd);
#else
		timer_setup(&fd->fifo_timer, fd_tlet_timer, 0);
#endif
		fd_timer_period_jiffies = msecs_to_jiffies(fd_timer_period_ms);
		dev_dbg(&fd->pdev->dev,"Using a timer for input (%i ms)\n",
			 jiffies_to_msecs(fd_timer_period_jiffies));
		mod_timer(&fd->fifo_timer, jiffies + fd_timer_period_jiffies);
	} else {
		struct resource *r;

		/* Disable interrupts */
		fd_writel(fd, ~0, FD_REG_EIC_IDR);

		tasklet_init(&fd->tlet, fd_tlet_interrupt, (unsigned long)fd);
		r = platform_get_resource(fd->pdev, IORESOURCE_IRQ, FD_IRQ);
		rv = request_any_context_irq(r->start, fd_irq_handler, 0,
					     r->name, fd);
		if (rv < 0) {
			dev_err(&fd->pdev->dev,
				"Failed to request the interrupt %i (%i)\n",
				platform_get_irq(fd->pdev, 0), rv);
			goto out_irq_request;
		}

		/*
		 * Then, configure the hardware: first fine delay,
		 * then vic, and finally the carrier
		 */

		fd_writel(fd, FD_TSBIR_TIMEOUT_W(10)	/* milliseconds */
			  |FD_TSBIR_THRESHOLD_W(15),	/* samples */
			  FD_REG_TSBIR);

		fd_writel(fd, FD_EIC_IER_TS_BUF_NOTEMPTY, FD_REG_EIC_IER);
	}

	/* let it run... */
	fd_writel(fd, FD_GCR_INPUT_EN, FD_REG_GCR);

	return 0;

out_irq_request:
	kfree(fd->sw_fifo.t);
	return rv;
}

void fd_irq_exit(struct fd_dev *fd)
{

	/* Stop input */
	fd_writel(fd, 0, FD_REG_GCR);

	if (fd_timer_period_ms) {
		del_timer_sync(&fd->fifo_timer);
	} else {
		fd_writel(fd, ~0, FD_REG_EIC_IDR);
		free_irq(platform_get_irq(fd->pdev, 0), fd);
	}
	kfree(fd->sw_fifo.t);
}
