// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <inttypes.h>
#include <time.h>

#include "fdelay-lib.h"

#include "tools-common.h"

char git_version[] = "git version: " GIT_VERSION;

void help(char *name)
{
	fprintf(stderr, "%s: Use \"%s [-V] [-d <dev>] [<opts>]\n",
		name, name);
	fprintf(stderr, " options:\n"
		"   -d <dev>        device ID (hexadecimal)\n"
		"   -o <output>     ouput channel: 1..4 (default 1)\n"
		"   -c <count>      default is 0 and means forever\n"
		"   -m <mode>       \"pulse\" (default), \"delay\", \"disable\"\n"
		"   -r <reltime>    relative time,  e.g. \"10m+20u\" -- use m,u,n,p and add/sub\n"
		"   -D <date>       absolute time, <secs>:<nano>\n"
		"   -T <period>     period, e.g. \"50m-20n\" -- use m,u,n,p and add/sub\n"
		"   -w <width>      like period; defaults to 50%% period\n"
		"   -t              wait for trigger before exiting\n"
		"   -p              pulse per seconds (sets -D <now> -T 1 -w 1u)\n"
		"   -1              10MHz (sets -D <now> -T 100ns -w 48ns)\n"
		"   -v              verbose (report action)\n");
	fprintf(stderr,"By default, the tool generates a continuous train of pulses (10 Hz frequency) on a given output.\n");
	exit(1);
}

struct fdelay_time t_width; /* save width here, add to start before acting */

/* This comes from oldtools/fdelay-pulse-tom.c, unchanged */
static void parse_time(char *s, struct fdelay_time *t)
{
	int64_t time_ps = 0;
	int64_t extra_seconds = 0;
	int64_t sign = 1;
	int64_t term = 0;
	int64_t scale = 1;

	const int64_t one_second = 1000000000000LL;

	char c, *buf = s;

	while ((c = *buf++) != 0) {
		switch (c) {
		case '+':
			if (scale == one_second)
				extra_seconds += sign * term;
			else
				time_ps += sign * term * scale;

			term = 0;
			sign = 1;
			break;
		case '-':
			if (scale == one_second)
				extra_seconds += sign * term;
			else
				time_ps += sign * term * scale;

			term = 0;
			sign = -1;
			break;

		case 's':
			scale = one_second;
			break;
		case 'm':
			scale = 1000000000LL;
			break;
		case 'u':
			scale = 1000000LL;
			break;
		case 'n':
			scale = 1000LL;
			break;
		case 'p':
			scale = 1LL;
			break;
		default:
			if (isdigit(c)) {
				term *= 10LL;
				term += (int64_t) (c - '0');
				break;
			} else {
				fprintf(stderr,
					"Error while parsing time string '%s'\n",
					s);
				exit(-1);
			}
		}
	}

	if (scale == one_second)
		extra_seconds += sign * term;
	else
		time_ps += sign * term * scale;

	while (time_ps < 0) {
		time_ps += one_second;
		extra_seconds--;
	}

	fdelay_pico_to_time((uint64_t *) & time_ps, t);

	t->utc += extra_seconds;

	if (0)
		printf("dbg: raw %"PRId64", %"PRId64", converted: %"PRIu64" s %"PRId32" ns %"PRId32" ps\n",
		       extra_seconds, time_ps, t->utc, t->coarse * 8,
		       t->frac * 8000 / 4096);
}


/* This comes from oldtools/fdelay-pulse-tom.c, unchanged */
static struct fdelay_time ts_add(struct fdelay_time a, struct fdelay_time b)
{
	a.frac += b.frac;
	if (a.frac >= 4096) {
		a.frac -= 4096;
		a.coarse++;
	}
	a.coarse += b.coarse;
	if (a.coarse >= 125000000) {
		a.coarse -= 125000000;
		a.utc++;
	}
	a.utc += b.utc;
	return a;
}


/*
 * Some argument parsing is non-trivial, including setting
 * the default. These helpers just return void and exit on error
 */
#define COARSE_PER_SEC (125 * 1000 * 1000)

void parse_default(struct fdelay_pulse *p)
{
	memset(p, 0, sizeof(*p));
	memset(&t_width, 0, sizeof(struct fdelay_time));
	p->mode =  FD_OUT_MODE_PULSE;
	p->rep = -1; /* 1 pulse */

	p->start.utc = 0;
	/* Default settings are for 10Hz, 1us width */
	p->loop.coarse = COARSE_PER_SEC / 10;
	t_width.coarse = 125;
}

void parse_pps(struct fdelay_pulse *p)
{
	parse_default(p);

	t_width.coarse = COARSE_PER_SEC / 100; /* 10ms width */
	p->loop.coarse = 0;
	p->loop.utc = 1;
}

void parse_10mhz(struct fdelay_pulse *p)
{
	parse_default(p);

	t_width.coarse = 6 /* 48ns */;
	p->loop.coarse = 12 /* 96ns */;
	p->loop.frac = 2048 /* 4ns */;
}

void parse_reltime(struct fdelay_pulse *p, char *s)
{
	memset(&p->start, 0, sizeof(p->start));
	parse_time(s, &p->start);
}

void parse_abstime(struct fdelay_pulse *p, char *s)
{
	unsigned long long utc;
	unsigned long nanos;
	char c;

	if (sscanf(s, "%llu:%lu%c", &utc, &nanos, &c) != 2) {
		fprintf(stderr, "Wrong <sec>:<nano> string \"%s\"\n", s);
		exit(1);
	}
	p->start.utc = utc;
	p->start.coarse = nanos / 8;
	p->start.frac = (nanos % 8) * 512;
}

void parse_period(struct fdelay_pulse *p, char *s)
{
	memset(&p->loop, 0, sizeof(p->loop));
	parse_time(s, &p->loop);
}

void parse_width(struct fdelay_pulse *p, char *s)
{
	memset(&t_width, 0, sizeof(struct fdelay_time));
	parse_time(s, &t_width);
}

static void width_set_duty_cycle_50(struct fdelay_time *period,
				    struct fdelay_time *width)
{
	memset(width, 0, sizeof(struct fdelay_time));
	width->utc = period->utc / 2;
	width->coarse = period->coarse / 2;
	width->frac = period->frac / 2;
	if (period->utc & 0x1)
		width->coarse += 62500000;
	if (period->coarse & 0x1)
		width->frac += 2048;
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	int i, opt, dev = -1, err = 0, flags;
	/* our parameters */
	int count = 0, channel = -1;
	int trigger_wait = 0, verbose = 0;
	struct fdelay_pulse p;
	int has_custom_width = 0;

	/* Standard part of the file (repeated code) */
	if (tools_need_help(argc, argv))
		help(argv[0]);

	/* print versions if needed */
	print_version(argc, argv);

	err = fdelay_init();
	if (err) {
		fprintf(stderr, "%s: library initialization failed\n", argv[0]);
		exit(1);
	}

	parse_default(&p);

	/* Parse our specific arguments */
	while ((opt = getopt(argc, argv, "d:ho:c:m:r:D:T:w:tp1v")) != -1) {
		switch (opt) {
			char *rest;
		case 'd':
			dev = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'h':
			help(argv[0]);

		case 'o':
			channel = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			if (channel < 1 || channel > 4) {
				fprintf(stderr, "%s: channel \"%s\" out of range\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'c':
			count = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			p.rep = count ? count : -1 /* infinite */;
			break;
		case 'm':
			if (!strcmp(optarg, "disable"))
				p.mode = FD_OUT_MODE_DISABLED;
			else if (!strcmp(optarg, "pulse"))
				p.mode = FD_OUT_MODE_PULSE;
			else if (!strcmp(optarg, "delay"))
				p.mode = FD_OUT_MODE_DELAY;
			else {
				fprintf(stderr, "%s: invalid mode \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'r':
			parse_reltime(&p, optarg);
			break;
		case 'D':
			parse_abstime(&p, optarg);
			break;
#if 0 /* no frequency */
		case 'f':
			parse_freq(&p, optarg);
			break;
#endif
		case 'T':
			parse_period(&p, optarg);
			break;
		case 'w':
			parse_width(&p, optarg);
			has_custom_width = 1;
			break;
		case 't':
			trigger_wait = 1;
			break;
		case 'p':
			parse_pps(&p);
			break;
		case '1':
			parse_10mhz(&p);
			break;
		case 'v':
			verbose = 1;
			break;
		}
	}
	if (optind != argc)
		help(argv[0]); /* too many arguments */

	if (dev < 0) {
		fprintf(stderr, "%s: several boards, please pass -d\n",
			argv[0]);
		exit(1);
	}

	/* If no custom value, set duty-cyle 50%  */
	if (!has_custom_width)
		width_set_duty_cycle_50(&p.loop, &t_width);

	b = fdelay_open(dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	if(channel < 0)
	{
		fprintf(stderr, "%s: no channel specified (-o option missing).\n", argv[0]);
		exit(1);
	}

	/* Final fixes: if  reltime in pulse mode, add current time */
	if (p.mode == FD_OUT_MODE_PULSE && p.start.utc == 0) {
		struct fdelay_time current_board_time;

		fdelay_get_time(b, &current_board_time);
		/* Start next second, or next again if too near to overlap */
		p.start.utc = current_board_time.utc + 1;
		if (current_board_time.coarse > COARSE_PER_SEC * 9 / 10)
			p.start.utc++;
	}

	/* Report to user how parsing turned out to be */
	if(verbose)
	{
		printf("Parsed times:\n");
		tools_report_time("  start time: ", &p.start, TOOLS_UMODE_USER);
		tools_report_time("  pulse width:", &t_width, TOOLS_UMODE_USER);
		tools_report_time("  period:     ", &p.loop, TOOLS_UMODE_USER);
	}

	/* End is start + width, in every situation */
	p.end = ts_add(p.start, t_width);

	/* In delay mode, default is one pulse only; recover if wrong
	   The same rule apply also for the disabled mode */
	if ((p.mode == FD_OUT_MODE_DELAY || p.mode == FD_OUT_MODE_DISABLED) &&
	    p.rep <= 0)
		p.rep = 1;
	/* In delay mode, the minimum delay is 600ns; recover if wrong
	   The same rule apply also for the disabled mode */
	if ((p.mode == FD_OUT_MODE_DELAY || p.mode == FD_OUT_MODE_DISABLED) &&
	    p.start.utc == 0 && p.start.coarse < (600 / 8)) {
		p.start.coarse = 600 / 8;
		p.start.frac = 0;
	}
	/* Done. Report verbosely and activate the information we parsed */
	channel = FDELAY_OUTPUT_USER_TO_HW(channel);

	report_output_config(channel, &p, TOOLS_UMODE_USER);

	flags = fdelay_get_config_tdc(b);
	if (flags < 0) {
		err = flags;
		goto out;
	}
	flags &= ~FD_TDCF_DISABLE_INPUT;
	err = fdelay_set_config_tdc(b, flags);
	if (err) {
		fprintf(stderr, "%s: failed to configure TDC: %s\n", argv[0],
				fdelay_strerror(errno));
		goto out;
	}

	if ((err = fdelay_config_pulse(b, channel, &p)) < 0) {
		fprintf(stderr, "%s: fdelay_config_pulse(): %s\n",
			argv[0], strerror(-err));
		exit(1);
	}
	while (trigger_wait) {
		struct timespec ts = {
			.tv_sec = 0,
			.tv_nsec = 10 * 1000,
		};

		nanosleep(&ts, NULL);
		i = fdelay_has_triggered(b, channel);
		if (i < 0) {
			fprintf(stderr, "%s: waiting for trigger: %s\n",
				argv[0], strerror(errno));
			exit(1);
		}
		trigger_wait = !i;
	}

out:
	fdelay_close(b);
	fdelay_exit();
	return err;
}
