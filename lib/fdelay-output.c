/*
 * output-related functions
 *
 * Copyright (C) 2012 CERN (www.cern.ch)
 * Author: Alessandro Rubini <rubini@gnudd.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2 as published by the Free Software Foundation or, at your
 * option, any later version.
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/select.h>

#include <linux/zio.h>
#include <linux/zio-user.h>
#define FDELAY_INTERNAL
#include "fdelay-lib.h"

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

void fdelay_pico_to_time(uint64_t *pico, struct fdelay_time *time)
{
	uint64_t p = *pico;

	time->utc = p / (1000ULL * 1000ULL * 1000ULL * 1000ULL);
	p %= (1000ULL * 1000ULL * 1000ULL * 1000ULL);
	time->coarse = p / 8000;
	p %= 8000;
	time->frac = p * 4096 / 8000;
}

void fdelay_time_to_pico(struct fdelay_time *time, uint64_t *pico)
{
	uint64_t p;

	p = time->frac * 8000 / 4096;
	p += time->coarse * 8000;
	p += time->utc * (1000ULL * 1000ULL * 1000ULL * 1000ULL);
	*pico = p;
}

static  int __fdelay_get_ch_fd(struct __fdelay_board *b,
			       int channel, int *fdc)
{
	int ch14 = channel + 1;
	char fname[128];

	if (channel < 0 || channel > 3) {
		errno = EINVAL;
		return -1;
	}
	if (b->fdc[ch14] <= 0) {
		sprintf(fname, "%s-%i-0-ctrl", b->devbase, ch14);
		b->fdc[ch14] = open(fname, O_WRONLY | O_NONBLOCK);
		if (b->fdc[ch14] < 0)
			return -1;
	}
	*fdc = b->fdc[ch14];
	return 0;
}

int fdelay_config_pulse(struct fdelay_board *userb,
			       int channel, struct fdelay_pulse *pulse)
{
	__define_board(b, userb);
	struct zio_control ctrl = {0,};
	uint32_t *a;
	int fdc;

	if (__fdelay_get_ch_fd(b, channel, &fdc) < 0)
		return -1; /* errno already set */

	a = ctrl.attr_channel.ext_val;
	a[FD_ATTR_OUT_MODE] = pulse->mode;
	a[FD_ATTR_OUT_REP] = pulse->rep;

	a[FD_ATTR_OUT_START_H] = pulse->start.utc >> 32;
	a[FD_ATTR_OUT_START_L] = pulse->start.utc;
	a[FD_ATTR_OUT_START_COARSE] = pulse->start.coarse;
	a[FD_ATTR_OUT_START_FINE] = pulse->start.frac;

	a[FD_ATTR_OUT_END_H] = pulse->end.utc >> 32;
	a[FD_ATTR_OUT_END_L] = pulse->end.utc;
	a[FD_ATTR_OUT_END_COARSE] = pulse->end.coarse;
	a[FD_ATTR_OUT_END_FINE] = pulse->end.frac;

	a[FD_ATTR_OUT_DELTA_L] = pulse->loop.utc; /* only 0..f */
	a[FD_ATTR_OUT_DELTA_COARSE] = pulse->loop.coarse; /* only 0..f */
	a[FD_ATTR_OUT_DELTA_FINE] = pulse->loop.frac; /* only 0..f */

	/* we need to fill the nsample field of the control */
	ctrl.attr_trigger.std_val[1] = 1;
	ctrl.nsamples = 1;
	ctrl.ssize = 4;
	ctrl.nbits = 32;

	write(fdc, &ctrl, sizeof(ctrl));
	return 0;
}

static void fdelay_add_ps(struct fdelay_time *p, uint64_t ps)
{
	uint32_t coarse, frac;

	/* FIXME: this silently fails with ps > 10^12 = 1s */
	coarse = ps / 8000;
	frac = ((ps % 8000) << 12) / 8000;

	p->frac += frac;
	if (p->frac >= 4096) {
		p->frac -= 4096;
		coarse++;
	}
	p->coarse += coarse;
	if (p->coarse > 125*1000*1000) {
		p->coarse -= 125*1000*1000;
		p->utc++;
	}
}

/* The "pulse_ps" function relies on the previous one */
int fdelay_config_pulse_ps(struct fdelay_board *userb,
			   int channel, struct fdelay_pulse_ps *ps)
{
	struct fdelay_pulse p;

	p.mode = ps->mode;
	p.rep = ps->rep;
	p.start = ps->start;
	p.end = ps->start;
	fdelay_add_ps(&p.end, ps->length);
	fdelay_pico_to_time(&ps->period, &p.loop);
	return fdelay_config_pulse(userb, channel, &p);
}

int fdelay_get_config_pulse(struct fdelay_board *userb,
				int channel, struct fdelay_pulse *pulse)
{
	__define_board(b, userb);
	char s[32];
	uint32_t utc_h, utc_l, rep, mode;

	sprintf(s,"fd-ch%i/%s", channel + 1, "mode");
	if (fdelay_sysfs_get(b, s, &mode) < 0)
		return -1; /* errno already set */
	pulse->mode = mode;
	sprintf(s,"fd-ch%i/%s", channel + 1, "rep");
	if (fdelay_sysfs_get(b, s, &rep) < 0)
		return -1;
	pulse->rep = rep;

	sprintf(s,"fd-ch%i/%s", channel + 1, "start-h");
	if (fdelay_sysfs_get(b, s, &utc_h) < 0)
		return -1;
	sprintf(s,"fd-ch%i/%s", channel + 1, "start-l");
	if (fdelay_sysfs_get(b, s, &utc_l) < 0)
		return -1;
	pulse->start.utc = (((uint64_t)utc_h) << 32) | utc_l;
	sprintf(s,"fd-ch%i/%s", channel + 1, "start-coarse");
	if (fdelay_sysfs_get(b, s, &pulse->start.coarse) < 0)
		return -1;
	sprintf(s,"fd-ch%i/%s", channel + 1, "start-fine");
	if (fdelay_sysfs_get(b, s, &pulse->start.frac) < 0)
		return -1;

	sprintf(s,"fd-ch%i/%s", channel + 1, "end-h");
	if (fdelay_sysfs_get(b, s, &utc_h) < 0)
		return -1;
	sprintf(s,"fd-ch%i/%s", channel + 1, "end-l");
	if (fdelay_sysfs_get(b, s, &utc_l) < 0)
		return -1;
	pulse->end.utc = (((uint64_t)utc_h) << 32) | utc_l;
	sprintf(s,"fd-ch%i/%s", channel + 1, "end-coarse");
	if (fdelay_sysfs_get(b, s, &pulse->end.coarse) < 0)
		return -1;
	sprintf(s,"fd-ch%i/%s", channel + 1, "end-fine");
	if (fdelay_sysfs_get(b, s, &pulse->end.frac) < 0)
		return -1;

	sprintf(s,"fd-ch%i/%s", channel + 1, "delta-l");
	if (fdelay_sysfs_get(b, s, &utc_l) < 0)
		return -1;
	pulse->loop.utc = utc_l;
	sprintf(s,"fd-ch%i/%s", channel + 1, "delta-coarse");
	if (fdelay_sysfs_get(b, s, &pulse->loop.coarse) < 0)
		return -1;
	sprintf(s,"fd-ch%i/%s", channel + 1, "delta-fine");
	if (fdelay_sysfs_get(b, s, &pulse->loop.frac) < 0)
		return -1;

	return 0;
}

static void fdelay_subtract_ps(struct fdelay_time *t2,
				   struct fdelay_time *t1, int64_t *pico)
{
	uint64_t pico1, pico2;

	fdelay_time_to_pico(t2, &pico2);
	fdelay_time_to_pico(t1, &pico1);
	*pico = (int64_t)pico2 - pico1;
}

int fdelay_get_config_pulse_ps(struct fdelay_board *userb,
			       int channel, struct fdelay_pulse_ps *ps)
{
	struct fdelay_pulse pulse;

	if (fdelay_get_config_pulse(userb, channel, &pulse) < 0)
		return -1;
	ps->mode = pulse.mode;
	ps->rep = pulse.rep;
	ps->start = pulse.start;
	/* FIXME: subtraction can be < 0 */
	fdelay_subtract_ps(&pulse.end, &pulse.start, (int64_t *)&ps->length);
	fdelay_time_to_pico(&pulse.loop, &ps->period);

	return 0;
}
int fdelay_has_triggered(struct fdelay_board *userb, int channel)
{
	__define_board(b, userb);
	char s[32];
	uint32_t mode;

	sprintf(s,"fd-ch%i/mode", channel + 1);
	if (fdelay_sysfs_get(b, s, &mode) < 0)
		return -1; /* errno already set */
	return (mode & 0x80) != 0;
}


