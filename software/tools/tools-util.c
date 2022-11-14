#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <inttypes.h>

#include "fdelay-lib.h"
#include "tools-common.h"

extern void help(char *name); /* This is mandatory in all tools */
extern char git_version[];

void print_version(int argc, char **argv)
{
	if ((argc == 2) && (!strcmp(argv[1], "-V"))) {
		printf("%s %s\n", argv[0], git_version);
		printf("%s\n", libfdelay_version_s);
		printf("%s\n", libfdelay_zio_version_s);
		exit(0);
	}

}

void tools_getopt_d_i(int argc, char **argv, int *dev)
{
	char *rest;
	int opt;

	while ((opt = getopt(argc, argv, "d:h")) != -1) {
		switch (opt) {
		case 'd':
			*dev = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'h':
			help(argv[0]);
		}
	}
}

int tools_need_help(int argc, char **argv)
{
	if (argc != 2)
		return 0;
	if (!strcmp(argv[1], "--help"))
		return 1;
	return 0;
}

void tools_report_time(char *name, struct fdelay_time *t, int umode)
{
	unsigned long long picoseconds =
		t->coarse * 8000ULL +
		t->frac * 8000ULL / 4096ULL;

	printf("%s ", name);
	switch(umode) {
	case TOOLS_UMODE_USER:
		printf ("%10"PRIu64":%03llu,%03llu,%03llu,%03llu ps\n",
			t->utc,
			(picoseconds / (1000ULL * 1000 * 1000)),
			(picoseconds / (1000ULL * 1000) % 1000),
			(picoseconds / (1000ULL) % 1000),
			(picoseconds % 1000ULL));
		break;
	case TOOLS_UMODE_FLOAT:
		printf ("float %10"PRIu64".%012llu\n", t->utc,
			picoseconds);
		break;
	case TOOLS_UMODE_RAW:
		printf("raw   utc %10"PRIu64",  coarse %9"PRIu32",  frac %9"PRIu32"\n",
		       t->utc, t->coarse, t->frac);
		break;
	}
}

static struct fdelay_time fd_ts_sub(struct fdelay_time a, struct fdelay_time b)
{
	struct fdelay_time rv;
	int f, c = 0;
	int64_t u = 0;

	f = a.frac - b.frac;
	if(f < 0)
	{
	    f += 4096;
	    c--;
	}

	c += a.coarse - b.coarse;
	if(c < 0)
	{
	    c += 125 * 1000 * 1000;
	    u--;
	}

	u += a.utc - b.utc;
	rv.utc = u;
	rv.coarse = c;
	rv.frac = f;
	rv.seq_id = 0;
	rv.channel = 0;
	return rv;
}


static void report_output_config_human(int channel, struct fdelay_pulse *p)
{
	struct fdelay_time width;

	printf("Channel %i: ", FDELAY_OUTPUT_HW_TO_USER(channel));

	int m = p->mode & 0x7f;
	
	switch(m)
	{
		case FD_OUT_MODE_DISABLED:
			printf("disabled\n");
			return;
		case FD_OUT_MODE_PULSE:
			printf("pulse generator mode");
			break;
		case FD_OUT_MODE_DELAY:
			printf("delay mode");
			break;
		default:
			printf("unknown mode\n");
			return;
	} 

	if(p->mode & 0x80) 
		printf(" (triggered) ");

	tools_report_time(m == FD_OUT_MODE_DELAY ? "\n  delay:           " : "\n  start at:        ", 
			  &p->start, TOOLS_UMODE_USER);

	width = fd_ts_sub(p->end, p->start);
	tools_report_time("  pulse width:     ", &width, TOOLS_UMODE_USER);

	if(p->rep != 1)
	{
		printf("  repeat:                    ");
		if(p->rep == -1)
			printf("infinite\n");
		else
			printf("%d times\n", p->rep);
		tools_report_time("  period:          ", &p->loop, TOOLS_UMODE_USER);
	}
}

void report_output_config_raw(int channel, struct fdelay_pulse *p, int umode)
{
	char mode[80];
	int m = p->mode & 0x7f;
	
	if (m == FD_OUT_MODE_DISABLED) strncpy(mode, "disabled", sizeof(mode));
	else if (m == FD_OUT_MODE_PULSE) strncpy(mode, "pulse", sizeof(mode));
	else if (m == FD_OUT_MODE_DELAY) strncpy(mode, "delay", sizeof(mode));
	else snprintf(mode, sizeof(mode), "%i (0x%04x)", p->mode, p->mode);

	if (p->mode & 0x80) 
	strncat(mode, " (triggered)", sizeof(mode) - strlen(mode));
	printf("Channel %i, mode %s, repeat %i %s\n",
		FDELAY_OUTPUT_HW_TO_USER(channel), mode,
		p->rep, p->rep == -1 ? "(infinite)" : "");
	tools_report_time("start", &p->start, umode);
	tools_report_time("end  ", &p->end, umode);
	tools_report_time("loop ", &p->loop, umode);
}

void report_output_config(int channel, struct fdelay_pulse *p, int umode)
{
    switch(umode)
    {
	case TOOLS_UMODE_USER: 
		report_output_config_human(channel, p);
		break;
	case TOOLS_UMODE_RAW: 
	case TOOLS_UMODE_FLOAT: 
		report_output_config_raw(channel, p, umode);
	default: 
	    break;
    }
}
